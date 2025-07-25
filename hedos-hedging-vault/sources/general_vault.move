module delta_hedging::general_vault {
    use aptos_framework::table::{Self, Table};
    use aptos_framework::event::{emit};
    use aptos_framework::object::{Self, ExtendRef};
    use aptos_framework::coin::{Self};
    use aptos_framework::aptos_coin::AptosCoin;
    use aptos_framework::account;

    use std::signer::{Self};
    use std::string::{String};
    use std::vector;
    
    // use delta_hedging::math::{I64, init_i64, get_value, is_negative, sub, safe_sub};
    use delta_hedging::math::{safe_sub};
    use delta_hedging::math256::{I256, init_i256, get_value_256, is_negative_256, sub_256, safe_sub_u256};

    use delta_hedging::white_list::{only_admin, add_admin};
    use delta_hedging::token::{transfer_usdc, transfer_apt, get_usdc_balance, update_balance};
    use delta_hedging::interact_merkle_trade::{simple_trade_v2};
    use delta_hedging::interact_amnis::{stake, unstake_amAPT, price_stAPT};
    use delta_hedging::interact_cellana::{swap_USDC_to_APT, swap_APT_to_USDC, swap_amAPT_to_USDC, get_amounts_out_USDC_APT_cellana, get_amounts_out_APT_USDC_cellana, get_amounts_out_USDC_amAPT_cellana, get_amounts_out_amAPT_USDC_cellana};
    use delta_hedging::fund_fee::{update_current_deposited};
    use delta_hedging::interact_aries::{Self};
    use delta_hedging::third_party::{Self, ThirdParty};

    use amnis::amapt_token::AmnisApt;
    use amnis::stapt_token::StakedApt;
    use wrapped_coins::wrapped_coins::WrappedUSDC;

    const DELTA_HEDGING: address = @delta_hedging;
    const PRECISION: u128 = 100000000;

    use std::string;

    const NOT_ENOUGH_SHARE: u64 = 997;
    const NOT_ENOUGH_FUND_FEE: u64 = 996;
    const NOT_ENOUGH_BALANCE: u64 = 995;


    fun get_pair(): string::String {
        string::utf8(b"APT_USD")
    }

    fun stringAPT(): string::String {
        string::utf8(b"APT")
    }

    fun stringUSDC(): string::String {
        string::utf8(b"USDC")
    }

    #[event]
    struct CreateNewVault has drop, store {
        new_vault_address: address
    }

    struct Vault has key {
        total_value_lock: u64,
        total_share_of_safety_vault: u256,
        users_share_in_safety_vault: Table<address, u256>,
        total_share_of_risky_vault: u256,
        users_share_in_risky_vault: Table<address, u256>,
    
        users_amount_in_safety_vault: Table<address, u64>,
        users_amount_in_risky_vault: Table<address, u64>,
        users_amount_fee_in_safety_vault: Table<address, I256>,
        users_amount_fee_in_risky_vault: Table<address, I256>,

        total_perpeptual: u64,
        total_staked: u64,

        fund_fee: I256,
        fund_fee_risky_rate_numerator: u64,
        fund_fee_risky_rate_denominator: u64, 
    }

    struct BackupVault has key {
        total_value_lock: u64,
    }

    struct VaultRef has key {
        vault_address: address,
        vault_extend_ref: ExtendRef,
    }

    struct BackupVaultRef has key {
        vault_address: address,
        vault_extend_ref: ExtendRef,
    }

    struct AdminRef has key {
        admin_address: address,
        admin_extend_ref: ExtendRef,
    }

    #[event]
    struct Deposited has drop, store {
        account: address,
        amount: u64,
        is_risky: bool,
    }

    #[event]
    struct Withdrawn has drop, store {
        account: address,
        amount: u64,
        is_risky: bool,
    }

    #[event]
    struct Withdraw has drop, store {
        account: address,
        amount: u64,
        funding_fee_value: u256,
        funding_fee_is_negative: bool,
        is_risky: bool,
    }

    #[event]
    struct OpenPerp has drop, store {
        collateral_delta: u64,
        leverage: u64,
        pair: String
    }

    #[event]
    struct ClosePerp has drop, store {
        collateral_delta: u64,
        leverage: u64,
        pair: String
    }

    #[event]
    struct Stake has drop, store {
        amount: u64
    }

    #[event]
    struct UnStake has drop, store {
        amount: u64
    }

    #[event]
    struct DepositLending has drop, store {
        amount: u64,
        token: String
    }

    #[event]
    struct BorrowLending has drop, store {
        amount: u64,
        token: String
    }

    #[event]
    struct RepayLending has drop, store {
        amount: u64,
        token: String
    }

    #[event]
    struct WithdrawLending has drop, store {
        amount: u64,
        token: String
    }

    #[view]
    public fun get_apt_balance(addr: address): u64 {
        if (account::exists_at(addr)) {
            coin::balance<AptosCoin>(addr)
        } else {
            0
        }
    }

    #[view]
    public fun get_amAPT_balance(addr: address): u64{
        if (account::exists_at(addr)) {
            coin::balance<AmnisApt>(addr)
        } else {
            0
        }
    }

    #[view]
    public fun get_stAPT_balance(addr: address): u64{
        if (account::exists_at(addr)) {
            coin::balance<StakedApt>(addr)
        } else {
            0
        }
    }

    #[view]
    public fun get_vault_address(): address acquires VaultRef {
        let vault_ref = borrow_global<VaultRef>(DELTA_HEDGING);
        vault_ref.vault_address
    }

    #[view]
    public fun get_total_value_lock(): u64 acquires Vault, VaultRef {
        let vault_ref = borrow_global<VaultRef>(DELTA_HEDGING);
        let vault = borrow_global<Vault>(vault_ref.vault_address);
        vault.total_value_lock
    }

    #[view]
    public fun get_total_staked(): u64 acquires VaultRef {
        let vault_ref = borrow_global<VaultRef>(DELTA_HEDGING);
        let amount_stAPT = get_stAPT_balance(vault_ref.vault_address);

        let amount_balance_amAPT = get_amAPT_balance(vault_ref.vault_address);
        let amount_amAPT = ( (price_stAPT() as u128) * (amount_stAPT as u128) / (PRECISION as u128) ) as u64;
        let amount_amAPT_all = amount_amAPT + amount_balance_amAPT;
        let amount_usdc = get_amounts_out_amAPT_USDC_cellana(amount_amAPT_all);
        amount_usdc
    }

    #[view]
    public fun get_total_staked_current(): u64 acquires VaultRef {
        let vault_ref = borrow_global<VaultRef>(DELTA_HEDGING);
        let amount_stAPT = get_stAPT_balance(vault_ref.vault_address);

        let amount_balance_amAPT = get_amAPT_balance(vault_ref.vault_address);
        let amount_amAPT = ( (price_stAPT() as u128) * (amount_stAPT as u128) / (PRECISION as u128) ) as u64;
        let amount_amAPT_all = amount_amAPT + amount_balance_amAPT;
        let amount_usdc = get_amounts_out_APT_USDC_cellana(amount_amAPT_all);
        amount_usdc
    }

    #[view]
    public fun get_total_perpeptual(): u64 acquires Vault, VaultRef {
        let vault_ref = borrow_global<VaultRef>(DELTA_HEDGING);
        let vault = borrow_global<Vault>(vault_ref.vault_address);
        vault.total_perpeptual
    }

    #[view]
    public fun get_total_leding(): u64 acquires VaultRef {
        let vault_ref = borrow_global<VaultRef>(DELTA_HEDGING);
        let vault_address = vault_ref.vault_address;
        interact_aries::total_lending<WrappedUSDC>(vault_address)
    }

    #[view]
    public fun get_total_loaning(): u64 acquires VaultRef {
        let vault_ref = borrow_global<VaultRef>(DELTA_HEDGING);
        let vault_address = vault_ref.vault_address;
        interact_aries::total_loaning<AptosCoin>(vault_address) as u64
    }

    #[view]
    public fun user_share(user: address): (u256, u256) acquires Vault, VaultRef {
        let vault_ref = borrow_global<VaultRef>(DELTA_HEDGING);
        let vault = borrow_global_mut<Vault>(vault_ref.vault_address);

        let safety_amount = if (table::contains(&vault.users_share_in_safety_vault, user)) {
            *table::borrow(&vault.users_share_in_safety_vault, user)
        } else {
            0
        };

        let risky_amount = if (table::contains(&vault.users_share_in_risky_vault, user)) {
            *table::borrow(&vault.users_share_in_risky_vault, user)
        } else {
            0
        };

        (safety_amount, risky_amount)
    }

    #[view]
    public fun total_share(): (u256, u256) acquires Vault, VaultRef {
        let vault_ref = borrow_global<VaultRef>(DELTA_HEDGING);
        let vault = borrow_global_mut<Vault>(vault_ref.vault_address);

        let safety_total_share = vault.total_share_of_safety_vault;
        let risky_total_share = vault.total_share_of_risky_vault;
        (safety_total_share, risky_total_share)
    }

    #[view]
    public fun fund_fee_ratio(): (u64, u64) acquires Vault, VaultRef {
        let vault_ref = borrow_global<VaultRef>(DELTA_HEDGING);
        let vault_address = vault_ref.vault_address;
        let risky_rate_numerator = borrow_global<Vault>(vault_address).fund_fee_risky_rate_numerator;
        let risky_rate_denominator = borrow_global<Vault>(vault_address).fund_fee_risky_rate_denominator;
      
        (risky_rate_numerator, risky_rate_denominator)
    }
    
    public entry fun init_vault(signer: &signer) acquires VaultRef {
        only_admin(signer);
        let constructor_ref = &object::create_object(DELTA_HEDGING);
        let vault_signer = &object::generate_signer(constructor_ref);
        let extend_ref = object::generate_extend_ref(constructor_ref);
        let new_vault_address = signer::address_of(vault_signer);

        let new_vault = Vault {
            total_value_lock: 0,
            total_share_of_safety_vault: 0,
            total_share_of_risky_vault: 0,

            users_share_in_safety_vault: table::new<address, u256>(),
            users_share_in_risky_vault: table::new<address, u256>(),

            users_amount_in_risky_vault: table::new<address, u64>(),
            users_amount_in_safety_vault: table::new<address, u64>(),

            users_amount_fee_in_risky_vault: table::new<address, I256>(),
            users_amount_fee_in_safety_vault: table::new<address, I256>(),
            total_perpeptual: 0,
            total_staked: 0,
            fund_fee: init_i256(0, false),
            fund_fee_risky_rate_numerator: 0,
            fund_fee_risky_rate_denominator: 0,
        };

        move_to(vault_signer, new_vault);   

        if (!exists<VaultRef>(DELTA_HEDGING)) {
            move_to(signer, VaultRef {
                vault_address: new_vault_address,
                vault_extend_ref: extend_ref,
            })
        } else {
            let vault_ref = borrow_global_mut<VaultRef>(DELTA_HEDGING);
            vault_ref.vault_address = new_vault_address;
            vault_ref.vault_extend_ref = extend_ref;
        };

        emit(CreateNewVault {
            new_vault_address: new_vault_address
        });
    }

    public entry fun init_backup_vault(signer: &signer) acquires BackupVaultRef {
        only_admin(signer);
        let constructor_ref = &object::create_object(DELTA_HEDGING);
        let vault_signer = &object::generate_signer(constructor_ref);
        let extend_ref = object::generate_extend_ref(constructor_ref);
        let new_vault_address = signer::address_of(vault_signer);

        let new_vault = BackupVault {
            total_value_lock: 0,
        };

        move_to(vault_signer, new_vault);   

        if (!exists<BackupVaultRef>(DELTA_HEDGING)) {
            move_to(signer, BackupVaultRef {
                vault_address: new_vault_address,
                vault_extend_ref: extend_ref,
            })
        } else {
            let vault_ref = borrow_global_mut<BackupVaultRef>(DELTA_HEDGING);
            vault_ref.vault_address = new_vault_address;
            vault_ref.vault_extend_ref = extend_ref;
        };
    }

    public entry fun init_admin_ref(signer: &signer) acquires AdminRef {
        only_admin(signer);
        let constructor_ref = &object::create_object(DELTA_HEDGING);
        let admin_signer = &object::generate_signer(constructor_ref);
        let extend_ref = object::generate_extend_ref(constructor_ref);
        let new_admin_address = signer::address_of(admin_signer);

        add_admin(signer, new_admin_address);

        if (!exists<AdminRef>(DELTA_HEDGING)) {
            move_to(admin_signer, AdminRef {
                admin_address: new_admin_address,
                admin_extend_ref: extend_ref,
            })
        } else {
            let admin_ref = borrow_global_mut<AdminRef>(DELTA_HEDGING);
            admin_ref.admin_address = new_admin_address;
            admin_ref.admin_extend_ref = extend_ref;
        };

    }

    public entry fun register_aries_vault(signer: &signer) acquires VaultRef {
        only_admin(signer);
        let vault_ref = borrow_global<VaultRef>(DELTA_HEDGING);
        let vault_signer = &object::generate_signer_for_extending(&vault_ref.vault_extend_ref);

        interact_aries::register_user(vault_signer);
    }

    public entry fun register_aries_backup_vault(signer: &signer) acquires BackupVaultRef {
        only_admin(signer);
        let vault_ref = borrow_global<BackupVaultRef>(DELTA_HEDGING);
        let vault_signer = &object::generate_signer_for_extending(&vault_ref.vault_extend_ref);

        interact_aries::register_user(vault_signer);
    }

    public entry fun transfer_internal_vault(signer: &signer, amount: u64, official_to_backup: bool, token: String) acquires VaultRef, BackupVaultRef {
        only_admin(signer);
        let vault_ref = borrow_global<VaultRef>(DELTA_HEDGING);
        let backup_vault_ref = borrow_global<BackupVaultRef>(DELTA_HEDGING);

        let from = &object::generate_signer_for_extending(&vault_ref.vault_extend_ref);
        let to = backup_vault_ref.vault_address;

        if (!official_to_backup) {
            from = &object::generate_signer_for_extending(&backup_vault_ref.vault_extend_ref);
            to = vault_ref.vault_address;
        };

        if (token == string::utf8(b"USDC")) {
            transfer_usdc(from, to, amount);
        } else if (token == string::utf8(b"APT")) {
            transfer_apt(from, to, amount);
        } else {
            abort 1;
        };
    }

    public fun register_aries() {
    }

    fun update_share_table(share_table: &mut Table<address, u256>, account: address, delta_share: u256, increase: bool) {
        let share = table::borrow_mut_with_default(share_table, account, 0);
        
        if (increase) {
            *share += delta_share;
        } else {
            assert!(*share >= delta_share, NOT_ENOUGH_SHARE);
            *share -= delta_share;
        };
    }

    fun set_share_table(share_table: &mut Table<address, u256>, account: address) {
        let share = table::borrow_mut_with_default(share_table, account, 0);
        *share = 0;
    }

    fun update_fund_fee_table(_share_table: &mut Table<address, I256>, _account: address, _value: u256, _is_negative: bool) {
    }

    public entry fun deposit_risky_vault(signer: &signer, account: address, amount: u64, total_value: u256, _value: u256, _is_negative:bool) acquires Vault, VaultRef {
        let vault_ref = borrow_global<VaultRef>(DELTA_HEDGING);
        let vault = borrow_global_mut<Vault>(vault_ref.vault_address);

        let user_share: u256;
        let total_share = vault.total_share_of_risky_vault;
        if( total_share == 0) {
            user_share = (amount as u256) * 1_000_000;
        } else user_share = (total_share * (amount as u256)) / total_value;

        update_share_table(&mut vault.users_share_in_risky_vault, account, user_share, true);
        update_current_deposited(0, amount, true);
        vault.total_value_lock += amount;
        vault.total_share_of_risky_vault += user_share;

        transfer_usdc(signer, vault_ref.vault_address, amount);

        emit(Deposited {
            account,
            amount,
            is_risky: true,
        });
    }

    public entry fun deposit_safety_vault(signer: &signer, account: address, amount: u64, total_value: u256, _value: u256, _is_negative:bool) acquires Vault, VaultRef {
        let vault_ref = borrow_global<VaultRef>(DELTA_HEDGING);
        let vault = borrow_global_mut<Vault>(vault_ref.vault_address);

        let user_share: u256;
        let total_share = vault.total_share_of_safety_vault;
        if( total_share == 0) {
            user_share = (amount as u256) * 1_000_000;
        } else user_share = (total_share * (amount as u256)) / total_value;

        update_share_table(&mut vault.users_share_in_safety_vault, account, user_share, true);
        update_current_deposited(amount, 0, true);

        vault.total_value_lock += amount;
        vault.total_share_of_safety_vault += user_share;

        transfer_usdc(signer, vault_ref.vault_address, amount);
        
        emit(Deposited {
            account,
            amount,
            is_risky: false,
        });
    }

    public entry fun open_position(_signer: &signer, collateral_delta: u64, leverage: u64, is_long: bool, market_skew: bool) acquires Vault, VaultRef {
        only_admin(_signer);
        let vault_ref = borrow_global<VaultRef>(DELTA_HEDGING);
        let vault_signer = &object::generate_signer_for_extending(&vault_ref.vault_extend_ref);
        let pair = get_pair();
        simple_trade_v2(vault_signer, vault_ref.vault_address, collateral_delta, leverage, is_long, true, market_skew, pair);

        let vault = borrow_global_mut<Vault>(vault_ref.vault_address);
        vault.total_perpeptual += collateral_delta;
        emit(OpenPerp {
            collateral_delta,
            leverage,
            pair
        });
    }

    public entry fun open_position_backup(_signer: &signer, collateral_delta: u64, leverage: u64, is_long: bool, market_skew: bool) acquires BackupVaultRef {
        only_admin(_signer);
        let vault_ref = borrow_global<BackupVaultRef>(DELTA_HEDGING);
        let vault_signer = &object::generate_signer_for_extending(&vault_ref.vault_extend_ref);
        let pair = get_pair();
        simple_trade_v2(vault_signer, vault_ref.vault_address, collateral_delta, leverage, is_long, true, market_skew, pair);
    }

    public entry fun open_position_v2(_signer: &signer, collateral_delta: u64, leverage: u64, is_long: bool, market_skew: bool, is_official: bool) acquires Vault, VaultRef, BackupVaultRef {
        only_admin(_signer);
        if (is_official) {
            open_position(_signer, collateral_delta, leverage, is_long, market_skew);
        } else {
            open_position_backup(_signer, collateral_delta, leverage, is_long, market_skew);
        };
    }

    public entry fun close_position(_signer: &signer, collateral_delta: u64, leverage: u64, is_long: bool, market_skew: bool) acquires Vault, VaultRef {
        only_admin(_signer);
        let vault_ref = borrow_global<VaultRef>(DELTA_HEDGING);
        let vault_signer = &object::generate_signer_for_extending(&vault_ref.vault_extend_ref);
        let pair = get_pair();
        
        simple_trade_v2(vault_signer, vault_ref.vault_address, collateral_delta, leverage, is_long, false, market_skew, pair);

        let vault = borrow_global_mut<Vault>(vault_ref.vault_address);
        vault.total_perpeptual = safe_sub(vault.total_perpeptual, collateral_delta);
        emit(ClosePerp {
            collateral_delta: collateral_delta,
            leverage,
            pair
        });
    }

    public entry fun close_position_backup(_signer: &signer, collateral_delta: u64, leverage: u64, is_long: bool, market_skew: bool) acquires BackupVaultRef {
        only_admin(_signer);
        let vault_ref = borrow_global<BackupVaultRef>(DELTA_HEDGING);
        let vault_signer = &object::generate_signer_for_extending(&vault_ref.vault_extend_ref);
        let pair = get_pair();
        
        simple_trade_v2(vault_signer, vault_ref.vault_address, collateral_delta, leverage, is_long, false, market_skew, pair);
    }

    public entry fun close_position_v2(_signer: &signer, collateral_delta: u64, leverage: u64, is_long: bool, market_skew: bool, is_official: bool) acquires Vault, VaultRef, BackupVaultRef {
        only_admin(_signer);
        if (is_official) {
            close_position(_signer, collateral_delta, leverage, is_long, market_skew);
        } else {
            close_position_backup(_signer, collateral_delta, leverage, is_long, market_skew);
        };
    }

    public entry fun liquid_staking(_signer: &signer, amountUSDC: u64) acquires VaultRef {
        only_admin(_signer);
        let vault_ref = borrow_global<VaultRef>(DELTA_HEDGING);
        let vault_signer = &object::generate_signer_for_extending(&vault_ref.vault_extend_ref);
        let amountAPTMin = get_amounts_out_USDC_APT_cellana(amountUSDC);

        let amount_stake_before = get_apt_balance(vault_ref.vault_address);
        swap_USDC_to_APT(vault_signer, amountUSDC);
        let amount_stake_after = get_apt_balance(vault_ref.vault_address) ;
        let amount_stake = amount_stake_after - amount_stake_before;

        stake(vault_signer, amount_stake, vault_ref.vault_address);
        
        emit(Stake {
            amount: amountAPTMin
        })
    }

    public entry fun liquid_staking_backup(_signer: &signer, amountUSDC: u64) acquires BackupVaultRef {
        only_admin(_signer);
        let vault_ref = borrow_global<BackupVaultRef>(DELTA_HEDGING);
        let vault_signer = &object::generate_signer_for_extending(&vault_ref.vault_extend_ref);
        let amountAPTMin = get_amounts_out_USDC_APT_cellana(amountUSDC);

        let amount_stake_before = get_apt_balance(vault_ref.vault_address);
        swap_USDC_to_APT(vault_signer, amountUSDC);
        let amount_stake_after = get_apt_balance(vault_ref.vault_address) ;
        let amount_stake = amount_stake_after - amount_stake_before;

        stake(vault_signer, amount_stake, vault_ref.vault_address);
        
        emit(Stake {
            amount: amountAPTMin
        })
    }

    public entry fun liquid_staking_v2(_signer: &signer, amountUSDC: u64, is_official: bool) acquires VaultRef, BackupVaultRef {
        only_admin(_signer);
        if (is_official) {
            liquid_staking(_signer, amountUSDC);
        } else {
            liquid_staking_backup(_signer, amountUSDC);
        };
    }

    public entry fun liquid_staking_unstake_all(_signer: &signer) acquires VaultRef {
        only_admin(_signer);
        let vault_ref = borrow_global<VaultRef>(DELTA_HEDGING);
        let vault_signer = &object::generate_signer_for_extending(&vault_ref.vault_extend_ref);
        let usdc_before = get_usdc_balance(vault_ref.vault_address);
    
        let stAPT_balance = get_stAPT_balance(vault_ref.vault_address);
        unstake_amAPT(vault_signer, stAPT_balance, vault_ref.vault_address);
        
        let amAPT_balance = get_amAPT_balance(vault_ref.vault_address);
        
        swap_amAPT_to_USDC(vault_signer, amAPT_balance);
        let usdc_after = get_usdc_balance(vault_ref.vault_address);

        let amount_unstake = usdc_after - usdc_before;
       
        emit(UnStake {
            amount: amount_unstake
        })
    }

    public entry fun liquid_staking_unstake_all_backup(_signer: &signer) acquires BackupVaultRef {
        only_admin(_signer);
        let vault_ref = borrow_global<BackupVaultRef>(DELTA_HEDGING);
        let vault_signer = &object::generate_signer_for_extending(&vault_ref.vault_extend_ref);
        let usdc_before = get_usdc_balance(vault_ref.vault_address);
    
        let stAPT_balance = get_stAPT_balance(vault_ref.vault_address);
        unstake_amAPT(vault_signer, stAPT_balance, vault_ref.vault_address);
        
        let amAPT_balance = get_amAPT_balance(vault_ref.vault_address);
        
        swap_amAPT_to_USDC(vault_signer, amAPT_balance);
        let usdc_after = get_usdc_balance(vault_ref.vault_address);

        let amount_unstake = usdc_after - usdc_before;
       
        emit(UnStake {
            amount: amount_unstake
        })
    }

    public entry fun liquid_staking_unstake_all_v2(_signer: &signer, is_official: bool) acquires VaultRef, BackupVaultRef {
        only_admin(_signer);
        if (is_official) {
            liquid_staking_unstake_all(_signer);
        } else {
            liquid_staking_unstake_all_backup(_signer);
        };
    }

    public entry fun liquid_staking_unstake(_signer: &signer, amountUSDC: u64) acquires VaultRef {
        only_admin(_signer);
        let vault_ref = borrow_global<VaultRef>(DELTA_HEDGING);
        let vault_signer = &object::generate_signer_for_extending(&vault_ref.vault_extend_ref);
        let usdc_before = get_usdc_balance(vault_ref.vault_address);

        let amApt_unstake = get_amounts_out_USDC_amAPT_cellana(amountUSDC);
        
        let st_unstake = (PRECISION * (amApt_unstake as u128) / (price_stAPT() as u128) ) as u64;

        let amAPT_balance_before = get_amAPT_balance(vault_ref.vault_address);
        unstake_amAPT(vault_signer, st_unstake, vault_ref.vault_address);
        let amAPT_balance_after = get_amAPT_balance(vault_ref.vault_address);

        swap_amAPT_to_USDC(vault_signer, amAPT_balance_after - amAPT_balance_before);
        let usdc_after = get_usdc_balance(vault_ref.vault_address);

        let amount_unstake = usdc_after - usdc_before;
        
        emit(UnStake {
            amount: amount_unstake
        })
    }

    public entry fun liquid_staking_unstake_backup(_signer: &signer, amountUSDC: u64) acquires BackupVaultRef {
        only_admin(_signer);
        let vault_ref = borrow_global<BackupVaultRef>(DELTA_HEDGING);
        let vault_signer = &object::generate_signer_for_extending(&vault_ref.vault_extend_ref);
        let usdc_before = get_usdc_balance(vault_ref.vault_address);

        let amApt_unstake = get_amounts_out_USDC_amAPT_cellana(amountUSDC);
        
        let st_unstake = (PRECISION * (amApt_unstake as u128) / (price_stAPT() as u128) ) as u64;

        let amAPT_balance_before = get_amAPT_balance(vault_ref.vault_address);
        unstake_amAPT(vault_signer, st_unstake, vault_ref.vault_address);
        let amAPT_balance_after = get_amAPT_balance(vault_ref.vault_address);

        swap_amAPT_to_USDC(vault_signer, amAPT_balance_after - amAPT_balance_before);
        let usdc_after = get_usdc_balance(vault_ref.vault_address);

        let amount_unstake = usdc_after - usdc_before;
        
        emit(UnStake {
            amount: amount_unstake
        })
    }

    public entry fun liquid_staking_unstake_v2(_signer: &signer, amountUSDC: u64, is_official: bool) acquires VaultRef, BackupVaultRef {
        only_admin(_signer);
        if (is_official) {
            liquid_staking_unstake(_signer, amountUSDC);
        } else {
            liquid_staking_unstake_backup(_signer, amountUSDC);
        };
    }

    public entry fun lending_deposit(_signer: &signer, amount: u64, token: String) acquires VaultRef {
        only_admin(_signer);
        let vault_ref = borrow_global<VaultRef>(DELTA_HEDGING);
        let vault_signer = &object::generate_signer_for_extending(&vault_ref.vault_extend_ref);

        if (token == string::utf8(b"USDC")) {
            interact_aries::deposit_fa<WrappedUSDC>(vault_signer, amount);
        } else if (token == string::utf8(b"APT")) {
            interact_aries::deposit<AptosCoin>(vault_signer, amount, false);
        } else {
            abort 1;
        };

        emit(DepositLending {
            amount: amount,
            token: token
        });
    }

    public entry fun lending_deposit_backup(_signer: &signer, amount: u64, token: String) acquires BackupVaultRef {
        only_admin(_signer);
        let vault_ref = borrow_global<BackupVaultRef>(DELTA_HEDGING);
        let vault_signer = &object::generate_signer_for_extending(&vault_ref.vault_extend_ref);

        if (token == string::utf8(b"USDC")) {
            interact_aries::deposit_fa<WrappedUSDC>(vault_signer, amount);
        } else if (token == string::utf8(b"APT")) {
            interact_aries::deposit<AptosCoin>(vault_signer, amount, false);
        } else {
            abort 1;
        };

        emit(DepositLending {
            amount: amount,
            token: token
        });
    }

    public entry fun lending_deposit_v2(_signer: &signer, amount: u64, token: String, is_official: bool) acquires VaultRef, BackupVaultRef {
        only_admin(_signer);
        if (is_official) {
            lending_deposit(_signer, amount, token);
        } else {
            lending_deposit_backup(_signer, amount, token);
        };
    }

    public entry fun lending_borrow(_signer: &signer, amountAPT: u64) acquires VaultRef {
        only_admin(_signer);
        let vault_ref = borrow_global<VaultRef>(DELTA_HEDGING);
        let vault_signer = &object::generate_signer_for_extending(&vault_ref.vault_extend_ref);

        interact_aries::withdraw<AptosCoin>(vault_signer, amountAPT, true);

        emit(BorrowLending {
            amount: amountAPT,
            token: stringAPT()
        });
    }

    public entry fun lending_borrow_backup(_signer: &signer, amountAPT: u64) acquires BackupVaultRef {
        only_admin(_signer);
        let vault_ref = borrow_global<BackupVaultRef>(DELTA_HEDGING);
        let vault_signer = &object::generate_signer_for_extending(&vault_ref.vault_extend_ref);

        interact_aries::withdraw<AptosCoin>(vault_signer, amountAPT, true);

        emit(BorrowLending {
            amount: amountAPT,
            token: stringAPT()
        });
    }

    public entry fun lending_borrow_v2(_signer: &signer, amountAPT: u64, is_official: bool) acquires VaultRef, BackupVaultRef {
        only_admin(_signer);
        if (is_official) {
            lending_borrow(_signer, amountAPT);
        } else {
            lending_borrow_backup(_signer, amountAPT);
        };
    }

    public entry fun lending_deposit_and_borrow(_signer: &signer, amountUSDC: u64, amountAPT_borrow: u64) acquires VaultRef {
        only_admin(_signer);
        let vault_ref = borrow_global<VaultRef>(DELTA_HEDGING);
        let vault_signer = &object::generate_signer_for_extending(&vault_ref.vault_extend_ref);

        interact_aries::deposit_fa<WrappedUSDC>(vault_signer, amountUSDC);
        interact_aries::withdraw<AptosCoin>(vault_signer, amountAPT_borrow, true);

        emit(DepositLending {
            amount: amountUSDC,
            token: stringUSDC()
        });
        emit(BorrowLending {
            amount: amountAPT_borrow,
            token: stringAPT()
        });
    }

    public entry fun lending_deposit_and_borrow_backup(_signer: &signer, amountUSDC: u64, amountAPT_borrow: u64) acquires BackupVaultRef {
        only_admin(_signer);
        let vault_ref = borrow_global<BackupVaultRef>(DELTA_HEDGING);
        let vault_signer = &object::generate_signer_for_extending(&vault_ref.vault_extend_ref);

        interact_aries::deposit_fa<WrappedUSDC>(vault_signer, amountUSDC);
        interact_aries::withdraw<AptosCoin>(vault_signer, amountAPT_borrow, true);

        emit(DepositLending {
            amount: amountUSDC,
            token: stringUSDC()
        });
        emit(BorrowLending {
            amount: amountAPT_borrow,
            token: stringAPT()
        });
    }

    public entry fun lending_deposit_and_borrow_v2(_signer: &signer, amountUSDC: u64, amountAPT_borrow: u64, is_official: bool) acquires VaultRef, BackupVaultRef {
        only_admin(_signer);
        if (is_official) {
            lending_deposit_and_borrow(_signer, amountUSDC, amountAPT_borrow);
        } else {
            lending_deposit_and_borrow_backup(_signer, amountUSDC, amountAPT_borrow);
        };
    }

    public entry fun lending_deposit_and_borrow_by_rate(_signer: &signer, amountUSDC: u64, rate: u64) acquires VaultRef {
        only_admin(_signer);
        let vault_ref = borrow_global<VaultRef>(DELTA_HEDGING);
        let vault_signer = &object::generate_signer_for_extending(&vault_ref.vault_extend_ref);

        let (_, amountAPT_borrow) = interact_aries::deposit_and_borrow<WrappedUSDC, AptosCoin>(vault_signer, amountUSDC, rate);

        interact_aries::deposit_fa<WrappedUSDC>(vault_signer, amountUSDC);
        interact_aries::withdraw<AptosCoin>(vault_signer, amountAPT_borrow, true);

        emit(DepositLending {
            amount: amountUSDC,
            token: stringUSDC()
        });
        emit(BorrowLending {
            amount: amountAPT_borrow,
            token: stringAPT()
        });
    }

    #[view]
    public fun max_apt_borrow(amountUSDC: u64): u64 acquires VaultRef {
        let vault_ref = borrow_global<VaultRef>(DELTA_HEDGING);
        let vault_signer = &object::generate_signer_for_extending(&vault_ref.vault_extend_ref);

        let (_, amountAPT_borrow) = interact_aries::deposit_and_borrow<WrappedUSDC, AptosCoin>(vault_signer, amountUSDC, 80);

        amountAPT_borrow
    }

    public entry fun lending_repay(_signer: &signer, amountAPT: u64) acquires VaultRef {
        only_admin(_signer);
        let vault_ref = borrow_global<VaultRef>(DELTA_HEDGING);
        let vault_signer = &object::generate_signer_for_extending(&vault_ref.vault_extend_ref);

        interact_aries::repay<AptosCoin>(vault_signer, amountAPT as u128);

        emit(RepayLending {
            amount: amountAPT,
            token: stringAPT()
        });
    }

    public entry fun lending_repay_backup(_signer: &signer, amountAPT: u64) acquires BackupVaultRef {
        only_admin(_signer);
        let vault_ref = borrow_global<BackupVaultRef>(DELTA_HEDGING);
        let vault_signer = &object::generate_signer_for_extending(&vault_ref.vault_extend_ref);

        interact_aries::repay<AptosCoin>(vault_signer, amountAPT as u128);

        emit(RepayLending {
            amount: amountAPT,
            token: stringAPT()
        });
    }

    public entry fun lending_repay_v2(_signer: &signer, amountAPT: u64, is_official: bool) acquires VaultRef, BackupVaultRef {
        only_admin(_signer);
        if (is_official) {
            lending_repay(_signer, amountAPT);
        } else {
            lending_repay_backup(_signer, amountAPT);
        };
    }

    public entry fun lending_withdraw(_signer: &signer, amount: u64, token: String) acquires VaultRef {
        only_admin(_signer);
        let vault_ref = borrow_global<VaultRef>(DELTA_HEDGING);
        let vault_signer = &object::generate_signer_for_extending(&vault_ref.vault_extend_ref);

        if (token == string::utf8(b"USDC")) {
            interact_aries::withdraw_fa<WrappedUSDC>(vault_signer, amount, false);
        } else if (token == string::utf8(b"APT")) {
            interact_aries::withdraw<AptosCoin>(vault_signer, amount, false);
        } else {
            abort 1;
        };

        emit(WithdrawLending {
            amount: amount,
            token: token
        });
    }

    public entry fun lending_withdraw_backup(_signer: &signer, amount: u64, token: String) acquires BackupVaultRef {
        only_admin(_signer);
        let vault_ref = borrow_global<BackupVaultRef>(DELTA_HEDGING);
        let vault_signer = &object::generate_signer_for_extending(&vault_ref.vault_extend_ref);

        if (token == string::utf8(b"USDC")) {
            interact_aries::withdraw_fa<WrappedUSDC>(vault_signer, amount, false);
        } else if (token == string::utf8(b"APT")) {
            interact_aries::withdraw<AptosCoin>(vault_signer, amount, false);
        } else {
            abort 1;
        };

        emit(WithdrawLending {
            amount: amount,
            token: token
        });
    }

    public entry fun lending_withdraw_v2(_signer: &signer, amount: u64, token: String, is_official: bool) acquires VaultRef, BackupVaultRef {
        only_admin(_signer);
        if (is_official) {
            lending_withdraw(_signer, amount, token);
        } else {
            lending_withdraw_backup(_signer, amount, token);
        };
    }

    public entry fun lending_repay_and_withdraw(_signer: &signer, amountAPT_repay: u64, amountUSDC_withdraw: u64) acquires VaultRef {
        only_admin(_signer);
        let vault_ref = borrow_global<VaultRef>(DELTA_HEDGING);
        let vault_signer = &object::generate_signer_for_extending(&vault_ref.vault_extend_ref);

        interact_aries::repay<AptosCoin>(vault_signer, amountAPT_repay as u128);
        interact_aries::withdraw_fa<WrappedUSDC>(vault_signer, amountUSDC_withdraw, false);

        emit(RepayLending {
            amount: amountAPT_repay,
            token: stringAPT()
        });
        emit(WithdrawLending {
            amount: amountUSDC_withdraw,
            token: stringUSDC()
        });
    }

    public entry fun lending_repay_and_withdraw_backup(_signer: &signer, amountAPT_repay: u64, amountUSDC_withdraw: u64) acquires BackupVaultRef {
        only_admin(_signer);
        let vault_ref = borrow_global<BackupVaultRef>(DELTA_HEDGING);
        let vault_signer = &object::generate_signer_for_extending(&vault_ref.vault_extend_ref);

        interact_aries::repay<AptosCoin>(vault_signer, amountAPT_repay as u128);
        interact_aries::withdraw_fa<WrappedUSDC>(vault_signer, amountUSDC_withdraw, false);

        emit(RepayLending {
            amount: amountAPT_repay,
            token: stringAPT()
        });
        emit(WithdrawLending {
            amount: amountUSDC_withdraw,
            token: stringUSDC()
        });
    }

    public entry fun lending_repay_and_withdraw_v2(_signer: &signer, amountAPT_repay: u64, amountUSDC_withdraw: u64, is_official: bool) acquires VaultRef, BackupVaultRef {
        only_admin(_signer);
        if (is_official) {
            lending_repay_and_withdraw(_signer, amountAPT_repay, amountUSDC_withdraw);
        } else {
            lending_repay_and_withdraw_backup(_signer, amountAPT_repay, amountUSDC_withdraw);
        };
    }

    public entry fun lending_repay_and_withdraw_all(_signer: &signer) acquires VaultRef {
        only_admin(_signer);
        let vault_ref = borrow_global<VaultRef>(DELTA_HEDGING);
        let vault_signer = &object::generate_signer_for_extending(&vault_ref.vault_extend_ref);

        let amountAPT_repay = interact_aries::total_loaning<AptosCoin>(vault_ref.vault_address);
        interact_aries::repay<AptosCoin>(vault_signer, amountAPT_repay);

        let amountUSDC_withdraw = interact_aries::total_lending<WrappedUSDC>(vault_ref.vault_address);
        interact_aries::withdraw_fa<WrappedUSDC>(vault_signer, amountUSDC_withdraw, false);

        emit(RepayLending {
            amount: amountAPT_repay as u64,
            token: stringAPT()
        });
        emit(WithdrawLending {
            amount: amountUSDC_withdraw,
            token: stringUSDC()
        });
    }

    public entry fun lending_repay_and_withdraw_all_backup(_signer: &signer) acquires BackupVaultRef {
        only_admin(_signer);
        let vault_ref = borrow_global<BackupVaultRef>(DELTA_HEDGING);
        let vault_signer = &object::generate_signer_for_extending(&vault_ref.vault_extend_ref);

        let amountAPT_repay = interact_aries::total_loaning<AptosCoin>(vault_ref.vault_address);
        interact_aries::repay<AptosCoin>(vault_signer, amountAPT_repay);

        let amountUSDC_withdraw = interact_aries::total_lending<WrappedUSDC>(vault_ref.vault_address);
        interact_aries::withdraw_fa<WrappedUSDC>(vault_signer, amountUSDC_withdraw, false);

        emit(RepayLending {
            amount: amountAPT_repay as u64,
            token: stringAPT()
        });
        emit(WithdrawLending {
            amount: amountUSDC_withdraw,
            token: stringUSDC()
        });
    }

    public entry fun lending_repay_and_withdraw_all_v2(_signer: &signer, is_official: bool) acquires VaultRef, BackupVaultRef {
        only_admin(_signer);
        if (is_official) {
            lending_repay_and_withdraw_all(_signer);
        } else {
            lending_repay_and_withdraw_all_backup(_signer);
        };
    }

    public entry fun cellana_swap_APT_to_USDC(_signer: &signer, amountAPT: u64) acquires VaultRef {
        only_admin(_signer);
        let vault_ref = borrow_global<VaultRef>(DELTA_HEDGING);
        let vault_signer = &object::generate_signer_for_extending(&vault_ref.vault_extend_ref);

        swap_APT_to_USDC(vault_signer, amountAPT);
    }

    public entry fun cellana_swap_APT_to_USDC_v2(_signer: &signer, amountAPT: u64, is_official: bool) acquires VaultRef, BackupVaultRef {
        only_admin(_signer);
        let vault_ref = borrow_global<VaultRef>(DELTA_HEDGING);
        let backup_vault_ref = borrow_global<BackupVaultRef>(DELTA_HEDGING);

        let vault_signer = &object::generate_signer_for_extending(&vault_ref.vault_extend_ref);
        if (!is_official) {
            vault_signer = &object::generate_signer_for_extending(&backup_vault_ref.vault_extend_ref);
        };

        swap_APT_to_USDC(vault_signer, amountAPT);
    }

    public entry fun cellana_swap_USDC_to_APT(_signer: &signer, amountUSDC: u64) acquires VaultRef {
        only_admin(_signer);
        let vault_ref = borrow_global<VaultRef>(DELTA_HEDGING);
        let vault_signer = &object::generate_signer_for_extending(&vault_ref.vault_extend_ref);

        swap_USDC_to_APT(vault_signer, amountUSDC);
    }

    public entry fun cellana_swap_USDC_to_APT_v2(_signer: &signer, amountUSDC: u64, is_official: bool) acquires VaultRef, BackupVaultRef {
        only_admin(_signer);
        let vault_ref = borrow_global<VaultRef>(DELTA_HEDGING);
        let backup_vault_ref = borrow_global<BackupVaultRef>(DELTA_HEDGING);

        let vault_signer = &object::generate_signer_for_extending(&vault_ref.vault_extend_ref);
        if (!is_official) {
            vault_signer = &object::generate_signer_for_extending(&backup_vault_ref.vault_extend_ref);
        };

        swap_USDC_to_APT(vault_signer, amountUSDC);
    }

    public entry fun withdraw_safety(_signer: &signer, account:address, amount:u64, amountClose: u64, _leverage: u64, _amountUnstake:u64, total_value: u64 ) acquires Vault, VaultRef {
        only_admin(_signer);
        let vault_ref = borrow_global<VaultRef>(DELTA_HEDGING);
        let vault = borrow_global_mut<Vault>(vault_ref.vault_address);
        let vault_signer = &object::generate_signer_for_extending(&vault_ref.vault_extend_ref);

        let amount_withdraw = amount;
        let total_share = vault.total_share_of_safety_vault;
        let user_share = total_share * (amount_withdraw as u256) / (total_value as u256);

        update_share_table(&mut vault.users_share_in_safety_vault, account, user_share, false);
        update_current_deposited(amount_withdraw, 0, false);

        vault.total_value_lock = safe_sub(vault.total_value_lock, amount_withdraw);
        vault.total_share_of_safety_vault = safe_sub_u256(vault.total_share_of_safety_vault, user_share);
        vault.total_perpeptual = safe_sub(vault.total_perpeptual, amountClose);

        transfer_usdc(vault_signer, account, amount_withdraw);


        emit(Withdrawn {
            account,
            amount: amount_withdraw,
            is_risky: false,
        });
    }

    public entry fun withdraw_risky(_signer: &signer, account:address, amount:u64, amountClose: u64, _leverage: u64, _amountUnstake:u64, total_value: u64 ) acquires Vault, VaultRef {
        only_admin(_signer);
        let vault_ref = borrow_global<VaultRef>(DELTA_HEDGING);
        let vault = borrow_global_mut<Vault>(vault_ref.vault_address);
        let vault_signer = &object::generate_signer_for_extending(&vault_ref.vault_extend_ref);

        let amount_withdraw = amount;
        let total_share = vault.total_share_of_risky_vault;
        let user_share = total_share * (amount_withdraw as u256) / (total_value as u256);

        update_share_table(&mut vault.users_share_in_risky_vault, account, user_share, false);
        update_current_deposited(0, amount_withdraw, false);

        vault.total_value_lock = safe_sub(vault.total_value_lock, amount_withdraw);
        vault.total_share_of_risky_vault = safe_sub_u256(vault.total_share_of_risky_vault, user_share);
        vault.total_perpeptual = safe_sub(vault.total_perpeptual, amountClose);

        transfer_usdc(vault_signer, account, amount_withdraw);

        emit(Withdrawn {
            account,
            amount: amount_withdraw,
            is_risky: true,
        });
    }

    public entry fun withdraw_safety_user_v1(_signer: &signer, account:address, amount:u64, amountClose: u64, leverage: u64, market_skew: bool, amountUnstake:u64, total_value: u64, close_all: bool ) acquires Vault, VaultRef {
        let vault_ref = borrow_global<VaultRef>(DELTA_HEDGING);
        let vault = borrow_global_mut<Vault>(vault_ref.vault_address);
        let usdc_balance = get_usdc_balance(vault_ref.vault_address);
        let vault_signer = &object::generate_signer_for_extending(&vault_ref.vault_extend_ref);

        if (!close_all) {
            let amount_remain_transfer;
            if( usdc_balance > amount && amountClose == 0 && amountUnstake == 0 )
                amount_remain_transfer = amount
            else amount_remain_transfer = usdc_balance;

            if( amount_remain_transfer != 0 )
            {   
                let total_share = vault.total_share_of_safety_vault;
                let user_share = (total_share * (amount_remain_transfer as u256)) / (total_value as u256);

                update_share_table(&mut vault.users_share_in_safety_vault, account, user_share, false);

                vault.total_value_lock = safe_sub(vault.total_value_lock, amount_remain_transfer);
                vault.total_share_of_safety_vault = safe_sub_u256(vault.total_share_of_safety_vault, user_share);
                transfer_usdc(vault_signer, account, amount_remain_transfer);
                update_current_deposited(amount_remain_transfer, 0, false);
            };

            if( amountClose !=0 && amountUnstake !=0 ){
                withdraw_safety_vault_v1(_signer, account, amountClose, leverage, market_skew, amountUnstake);
            };

            emit(Withdrawn {
                account,
                amount: amount_remain_transfer + amountClose + amountUnstake,
                is_risky: false,
            });
        }
        else {
            let pair = get_pair();
            simple_trade_v2(vault_signer, vault_ref.vault_address, amountClose, leverage, false, false, market_skew, pair);
        
            let amApt_unstake = get_amounts_out_USDC_amAPT_cellana(amountUnstake);
            let st_unstake = (PRECISION * (amApt_unstake as u128) / (price_stAPT() as u128) ) as u64;

            let amAPT_balance_before = get_amAPT_balance(vault_ref.vault_address);
            unstake_amAPT(vault_signer, st_unstake, vault_ref.vault_address);
            let amAPT_balance_after = get_amAPT_balance(vault_ref.vault_address);

            swap_amAPT_to_USDC(vault_signer, amAPT_balance_after - amAPT_balance_before);
            
            emit(Withdrawn {
                account,
                amount: amount,
                is_risky: false,
            });
        }
    }

    public entry fun withdraw_risky_user_v1(_signer: &signer, account:address, amount:u64, amountClose: u64, leverage: u64, market_skew: bool, amountUnstake:u64, total_value: u64, close_all: bool ) acquires Vault, VaultRef {
        let vault_ref = borrow_global<VaultRef>(DELTA_HEDGING);
        let vault = borrow_global_mut<Vault>(vault_ref.vault_address);
        let usdc_balance = get_usdc_balance(vault_ref.vault_address);
        let vault_signer = &object::generate_signer_for_extending(&vault_ref.vault_extend_ref);

        if (!close_all) {          
            let amount_remain_transfer;
            if( usdc_balance > amount && amountClose == 0 && amountUnstake == 0 )
                amount_remain_transfer = amount
            else amount_remain_transfer = usdc_balance;
            
            if( amount_remain_transfer != 0 )
            {   
                let total_share = vault.total_share_of_risky_vault;
                let user_share = (total_share * (amount_remain_transfer as u256)) / (total_value as u256);

                update_share_table(&mut vault.users_share_in_risky_vault, account, user_share, false);

                vault.total_value_lock = safe_sub(vault.total_value_lock, amount_remain_transfer);
                vault.total_share_of_risky_vault = safe_sub_u256(vault.total_share_of_risky_vault, user_share);
                transfer_usdc(vault_signer, account, amount_remain_transfer);
                update_current_deposited(0, amount_remain_transfer, false);
            };

            if( amountClose !=0 && amountUnstake !=0 )
                withdraw_risky_vault_v1(_signer, account, amountClose, leverage, market_skew, amountUnstake);

            emit(Withdrawn {
                account,
                amount: amount_remain_transfer + amountClose + amountUnstake,
                is_risky: true,
            });
        } else {
            let pair = get_pair();
            simple_trade_v2(vault_signer, vault_ref.vault_address, amountClose, leverage, false, false, market_skew, pair);
        
            let amApt_unstake = get_amounts_out_USDC_amAPT_cellana(amountUnstake);
            let st_unstake = (PRECISION * (amApt_unstake as u128) / (price_stAPT() as u128) ) as u64;

            let amAPT_balance_before = get_amAPT_balance(vault_ref.vault_address);
            unstake_amAPT(vault_signer, st_unstake, vault_ref.vault_address);
            let amAPT_balance_after = get_amAPT_balance(vault_ref.vault_address);

            swap_amAPT_to_USDC(vault_signer, amAPT_balance_after - amAPT_balance_before);
            
            emit(Withdrawn {
                account,
                amount: amount,
                is_risky: true,
            });
        }
    }   
    
    public entry fun withdraw_risky_vault_v1(_signer: &signer, account: address, amountClose: u64, leverage: u64, market_skew: bool, amountUnstake:u64) acquires VaultRef{
        let vault_ref = borrow_global<VaultRef>(DELTA_HEDGING);

        let vault_signer = &object::generate_signer_for_extending(&vault_ref.vault_extend_ref);
        let pair = get_pair();

        let usdc_before = get_usdc_balance(vault_ref.vault_address);
        update_balance(usdc_before);
        simple_trade_v2(vault_signer, vault_ref.vault_address, amountClose, leverage, false, false, market_skew, pair);

        let amApt_unstake = get_amounts_out_USDC_amAPT_cellana(amountUnstake);
        let st_unstake = (PRECISION * (amApt_unstake as u128) / (price_stAPT() as u128) ) as u64;

        let amAPT_balance_before = get_amAPT_balance(vault_ref.vault_address);
        unstake_amAPT(vault_signer, st_unstake, vault_ref.vault_address);
        let amAPT_balance_after = get_amAPT_balance(vault_ref.vault_address);

        swap_amAPT_to_USDC(vault_signer, amAPT_balance_after - amAPT_balance_before);

        emit(Withdrawn {
            account,
            amount: amountClose + amountUnstake,
            is_risky: true,
        });
    }

    public entry fun withdraw_safety_vault_v1(_signer: &signer, account: address, amountClose: u64, leverage: u64, market_skew: bool, amountUnstake:u64) acquires VaultRef{
        let vault_ref = borrow_global<VaultRef>(DELTA_HEDGING);

        let vault_signer = &object::generate_signer_for_extending(&vault_ref.vault_extend_ref);
        let pair = get_pair();

        let usdc_before = get_usdc_balance(vault_ref.vault_address);
        update_balance(usdc_before);
        simple_trade_v2(vault_signer, vault_ref.vault_address, amountClose, leverage, false, false, market_skew, pair);

        let amApt_unstake = get_amounts_out_USDC_amAPT_cellana(amountUnstake);
        let st_unstake = (PRECISION * (amApt_unstake as u128) / (price_stAPT() as u128) ) as u64;

        let amAPT_balance_before = get_amAPT_balance(vault_ref.vault_address);
        unstake_amAPT(vault_signer, st_unstake, vault_ref.vault_address);
        let amAPT_balance_after = get_amAPT_balance(vault_ref.vault_address);

        swap_amAPT_to_USDC(vault_signer, amAPT_balance_after - amAPT_balance_before);

        emit(Withdrawn {
            account,
            amount: amountClose + amountUnstake,
            is_risky: false,
        });
    }    

    fun withdraw_liquid(vault_signer: &signer, amountUnstake: u64, vault_address: address) {
        let amApt_unstake = get_amounts_out_USDC_amAPT_cellana(amountUnstake);
        let st_unstake = (PRECISION * (amApt_unstake as u128) / (price_stAPT() as u128) ) as u64;

        let amAPT_balance_before = get_amAPT_balance(vault_address);
        unstake_amAPT(vault_signer, st_unstake, vault_address);
        let amAPT_balance_after = get_amAPT_balance(vault_address);

        swap_amAPT_to_USDC(vault_signer, amAPT_balance_after - amAPT_balance_before);
    }

    fun withdraw_vault_internal(vault_signer: &signer, vault_address: address, actions: vector<ThirdParty>): u64 {
        let amount = 0;
        let i = 0;
        let len = vector::length(&actions);
        while (i < len) {
            let action = vector::borrow(&actions, i);
            let type = third_party::get_type_id(action);
            if (type == third_party::perp_id()) {
                let (amount_close, leverage, is_long, market_skew) = third_party::get_perp_param(action);
                simple_trade_v2(vault_signer, vault_address, amount_close, leverage, is_long, false, market_skew, get_pair());
                amount += amount_close;
            } else if (type == third_party::liquid_id()) {
                let amountUnstake = third_party::get_liquid_param(action);
                withdraw_liquid(vault_signer, amountUnstake, vault_address);
                amount += amountUnstake;
            } else if (type == third_party::lending_id()) {
                let (amount_withdraw, token_withdraw, amount_repay, _token_repay, action) = third_party::get_lending_param(action);
                amount += amount_withdraw;
                if (action == third_party::only_withdraw_id()) {
                    if (token_withdraw == string::utf8(b"USDC")) {
                        interact_aries::withdraw_fa<WrappedUSDC>(vault_signer, amount_withdraw, false);
                    } else if (token_withdraw == string::utf8(b"APT")) {
                        interact_aries::withdraw<AptosCoin>(vault_signer, amount_withdraw, false);
                    } else {
                        abort 1;
                    };
                } else if (action == third_party::repay_withdraw_id()) {
                    interact_aries::repay<AptosCoin>(vault_signer, amount_repay as u128);       
                    interact_aries::withdraw_fa<WrappedUSDC>(vault_signer, amount_withdraw, false);
                } else {
                    abort 1;
                };
            };
            i += 1;
        };

        amount
    }

    fun execute_action_internal(signer: &signer, data: vector <u64>): (u64, u64) acquires Vault, VaultRef, BackupVaultRef {
        only_admin(signer);
        
        let amountIn = 0;
        let amountOut = 0;

        let actions = third_party::unzip_input(data);
        let i = 0;
        let len = vector::length(&actions);

        while (i < len) {
            let action = vector::borrow(&actions, i);
            let type = third_party::get_type_id(action);
            let is_open = third_party::get_is_open(action);
            let is_official = third_party::get_is_official(action);
            if (type == third_party::perp_id()) {
                let (amount, leverage, is_long, market_skew) = third_party::get_perp_param(action);
                if (is_open) {
                    open_position_v2(signer, amount, leverage, is_long, market_skew, is_official);
                    amountIn += amount;
                } else {
                    close_position_v2(signer, amount, leverage, is_long, market_skew, is_official);
                    amountOut += amount;
                };
            } else if (type == third_party::liquid_id()) {
                let amount = third_party::get_liquid_param(action);
                if (is_open) {
                    liquid_staking_v2(signer, amount, is_official);
                    amountIn += amount;
                } else {
                    liquid_staking_unstake_v2(signer, amount, is_official);
                    amountOut += amount;
                }
            } else if (type == third_party::lending_id()) {
                let (amount_withdraw, token_withdraw, amount_repay, _token_repay, action) = third_party::get_lending_param(action);
                if (is_open) {
                    if (action == third_party::only_withdraw_id()) {
                        lending_deposit_v2(signer, amount_withdraw, token_withdraw, is_official);
                    } else if (action == third_party::repay_withdraw_id()) {
                        lending_deposit_and_borrow_v2(signer, amount_withdraw, amount_repay, is_official);
                    } else {
                        abort 1;
                    };
                    
                } else {
                    amountOut += amount_withdraw;
                    if (action == third_party::only_withdraw_id()) {
                        lending_withdraw_v2(signer, amount_withdraw, token_withdraw, is_official);
                    } else if (action == third_party::repay_withdraw_id()) {
                        amountIn += amount_repay;
                        lending_repay_and_withdraw_v2(signer, amount_repay, amount_withdraw, is_official);
                    } else {
                        abort 1;
                    };
                }
            };
            i += 1;
        };

        (amountIn, amountOut)
    }

    public entry fun execute_action(signer: &signer, data: vector <u64>) acquires Vault, VaultRef, BackupVaultRef {
        only_admin(signer);
        let (_, _) = execute_action_internal(signer, data);
    }

    fun withdraw_vault_internal_v2(data: vector <u64>): u64 acquires Vault, VaultRef, BackupVaultRef, AdminRef {
        let admin_ref = borrow_global<AdminRef>(DELTA_HEDGING);
        let admin_signer = &object::generate_signer_for_extending(&admin_ref.admin_extend_ref);
        
        let (_, amount) = execute_action_internal(admin_signer, data);

        amount
    }

    public entry fun withdraw_safety_vault_v2(
        _signer: &signer, 
        account: address,
        data: vector<u64>
    ) acquires Vault, VaultRef, BackupVaultRef, AdminRef {

        let amount = withdraw_vault_internal_v2(data);
        
        emit(Withdrawn {
            account,
            amount,
            is_risky: false,
        });
    }

    public entry fun withdraw_risky_vault_v2(
        _signer: &signer, 
        account: address,
        data: vector<u64>
    ) acquires Vault, VaultRef , BackupVaultRef, AdminRef {

        let amount = withdraw_vault_internal_v2(data);
        
        emit(Withdrawn {
            account,
            amount,
            is_risky: true,
        });
    }

    public entry fun withdraw_safety_user_v2(
        _signer: &signer, 
        account: address,
        amount: u64,
        total_value:  u64,
        close_all: bool,
        data: vector<u64>
    ) acquires Vault, VaultRef, BackupVaultRef, AdminRef {
        let vault_ref = borrow_global<VaultRef>(DELTA_HEDGING);
        let vault = borrow_global_mut<Vault>(vault_ref.vault_address);

        let backup_vault_ref = borrow_global<BackupVaultRef>(DELTA_HEDGING);
        let usdc_backup = get_usdc_balance(backup_vault_ref.vault_address);
        transfer_usdc(&object::generate_signer_for_extending(&backup_vault_ref.vault_extend_ref), vault_ref.vault_address, usdc_backup);

        let usdc_balance = get_usdc_balance(vault_ref.vault_address);
        let vault_signer = &object::generate_signer_for_extending(&vault_ref.vault_extend_ref);

        if (!close_all) {          
            let amount_remain_transfer;
            if( usdc_balance > amount && vector::length(&data) == 0)
                amount_remain_transfer = amount
            else amount_remain_transfer = usdc_balance;
            
            if( amount_remain_transfer != 0 )
            {   
                let total_share = vault.total_share_of_safety_vault;
                let user_share = (total_share * (amount_remain_transfer as u256)) / (total_value as u256);

                update_share_table(&mut vault.users_share_in_safety_vault, account, user_share, false);

                vault.total_value_lock = safe_sub(vault.total_value_lock, amount_remain_transfer);
                vault.total_share_of_safety_vault = safe_sub_u256(vault.total_share_of_safety_vault, user_share);
                transfer_usdc(vault_signer, account, amount_remain_transfer);
                update_current_deposited(0, amount_remain_transfer, false);
            };
        };
        
        if( vector::length(&data) != 0)
            withdraw_safety_vault_v2(_signer, account, data);

        emit(Withdrawn {
            account,
            amount: amount,
            is_risky: false,
        });
    }

    public entry fun withdraw_risky_user_v2(
        _signer: &signer, 
        account: address,
        amount: u64,
        total_value:  u64,
        close_all: bool,
        data: vector<u64>
    ) acquires Vault, VaultRef, BackupVaultRef, AdminRef {
        let vault_ref = borrow_global<VaultRef>(DELTA_HEDGING);
        let vault = borrow_global_mut<Vault>(vault_ref.vault_address);

        let backup_vault_ref = borrow_global<BackupVaultRef>(DELTA_HEDGING);
        let usdc_backup = get_usdc_balance(backup_vault_ref.vault_address);
        transfer_usdc(&object::generate_signer_for_extending(&backup_vault_ref.vault_extend_ref), vault_ref.vault_address, usdc_backup);

        let usdc_balance = get_usdc_balance(vault_ref.vault_address);
        let vault_signer = &object::generate_signer_for_extending(&vault_ref.vault_extend_ref);

        if (!close_all) {          
            let amount_remain_transfer;
            if( usdc_balance > amount && vector::length(&data) == 0)
                amount_remain_transfer = amount
            else amount_remain_transfer = usdc_balance;
            
            if( amount_remain_transfer != 0 )
            {   
                let total_share = vault.total_share_of_risky_vault;
                let user_share = (total_share * (amount_remain_transfer as u256)) / (total_value as u256);

                update_share_table(&mut vault.users_share_in_risky_vault, account, user_share, false);

                vault.total_value_lock = safe_sub(vault.total_value_lock, amount_remain_transfer);
                vault.total_share_of_risky_vault = safe_sub_u256(vault.total_share_of_risky_vault, user_share);
                transfer_usdc(vault_signer, account, amount_remain_transfer);
                update_current_deposited(0, amount_remain_transfer, false);
            };
        };
        
        if( vector::length(&data) != 0)
            withdraw_risky_vault_v2(_signer, account, data);

        emit(Withdrawn {
            account,
            amount: amount,
            is_risky: true,
        });
    }

    fun fund_fee_risky(value: u256, is_negative: bool): I256 acquires Vault, VaultRef {
        let fund_fee = init_i256(value, is_negative);
        let vault_address = borrow_global<VaultRef>(DELTA_HEDGING).vault_address;
        
        let risky_rate_numerator = borrow_global<Vault>(vault_address).fund_fee_risky_rate_numerator;
        let risky_rate_denominator = borrow_global<Vault>(vault_address).fund_fee_risky_rate_denominator;
        let fund_fee_risky: I256;
        if( is_negative_256(fund_fee) ) {
            return init_i256(get_value_256(fund_fee), true);
        };
        fund_fee_risky = init_i256(get_value_256(fund_fee) * (risky_rate_numerator as u256) / (risky_rate_denominator as u256), is_negative_256(fund_fee));

        fund_fee_risky
    }

    fun fund_fee_after_risky(value: u256, is_negative: bool): I256 acquires Vault, VaultRef {
        let fund_fee = init_i256(value, is_negative);
        let fund_fee_after_risky = fund_fee_risky(value, is_negative);

        sub_256(fund_fee, fund_fee_after_risky)
    }

    fun calc_fund_fee(
        _fund_fee: I256,
        _user_share: u256,
        _total_share: u256,
    ): I256 {
        let result: u256 = get_value_256(_fund_fee) * _user_share / _total_share;
        let is_negative: bool = false;

        init_i256(result, is_negative)
    }

    public fun total_fund_fee_in_risky_vault(value: u256, is_negative: bool): I256 acquires Vault, VaultRef {
        let fund_fee = init_i256(value, is_negative);
        let fund_fee_risky = fund_fee_risky(value, is_negative);
        let fund_fee_after_risky = fund_fee_after_risky(value, is_negative);

        let (safety_vault, risky_vault) = total_share();
        if (is_negative_256(fund_fee)) {
            return init_i256(get_value_256(fund_fee_risky), true);
        };
        let result = get_value_256(fund_fee_risky) + get_value_256(fund_fee_after_risky) * risky_vault / (safety_vault + risky_vault);
        let is_negative = is_negative_256(fund_fee_risky);

        init_i256(result, is_negative)
    }

    public fun total_fund_fee_in_safety_vault(value: u256, is_negative: bool): u256 acquires Vault, VaultRef {
        let result: u256 = 0;
        let fund_fee = init_i256(value, is_negative);
        
        let (safety_vault, risky_vault) = total_share();
        if (!is_negative_256(fund_fee)) {
            let fund_fee_after_risky = fund_fee_after_risky(value, is_negative);
            result = get_value_256(fund_fee_after_risky) * safety_vault / (safety_vault + risky_vault);
        };

        result
    }

    public entry fun set_fund_fee_risky_rate(signer: &signer, numerator: u64, denominator: u64) acquires Vault, VaultRef {
        only_admin(signer);
        let vault_address = borrow_global<VaultRef>(DELTA_HEDGING).vault_address;
        let vault = borrow_global_mut<Vault>(vault_address);

        vault.fund_fee_risky_rate_numerator = numerator;
        vault.fund_fee_risky_rate_denominator = denominator;
    }

    public entry fun set_fund_fee(_signer: &signer, _value: u256, _is_negative: bool) {    
    }

    public entry fun set_total_perp(signer: &signer, value_perp: u64) acquires Vault, VaultRef {
        only_admin(signer);
        let vault_address = borrow_global<VaultRef>(DELTA_HEDGING).vault_address;
        let vault = borrow_global_mut<Vault>(vault_address);
        vault.total_perpeptual = value_perp;
    }

    public entry fun set_total_value_lock(signer: &signer, value: u64) acquires Vault, VaultRef {
        only_admin(signer);
        let vault_address = borrow_global<VaultRef>(DELTA_HEDGING).vault_address;
        let vault = borrow_global_mut<Vault>(vault_address);
        vault.total_value_lock = value;
    }

    public entry fun redeem_usdc(signer: &signer, account:address, _amount:u64) acquires VaultRef {
        only_admin(signer);
        let vault_ref = borrow_global<VaultRef>(DELTA_HEDGING);
        let _usdc_balance = get_usdc_balance(vault_ref.vault_address);

        let vault_signer = &object::generate_signer_for_extending(&vault_ref.vault_extend_ref);
        transfer_usdc(vault_signer, account, _amount);  
    }

    public entry fun swap_amAPT_remain(_signer: &signer, account:address, _amount:u64) acquires VaultRef {
        let vault_ref = borrow_global<VaultRef>(DELTA_HEDGING);
        let vault_signer = &object::generate_signer_for_extending(&vault_ref.vault_extend_ref);

        let amAPT_balance = get_amAPT_balance(vault_ref.vault_address);
        swap_amAPT_to_USDC(vault_signer, amAPT_balance);
        let usdc_after = get_usdc_balance(vault_ref.vault_address);
       
        transfer_usdc(vault_signer, account, usdc_after);
    }

    public entry fun set_total_share(signer: &signer, _risky: u256, _safety: u256) acquires Vault, VaultRef {
        only_admin(signer);
        let vault_ref = borrow_global<VaultRef>(DELTA_HEDGING);
        let vault = borrow_global_mut<Vault>(vault_ref.vault_address);
        vault.total_share_of_risky_vault = _risky;
        vault.total_share_of_safety_vault = _safety;
    }

    public entry fun set_share_table_user(signer: &signer, account: address) acquires Vault, VaultRef{
        only_admin(signer);
        let vault_ref = borrow_global<VaultRef>(DELTA_HEDGING);
        let vault = borrow_global_mut<Vault>(vault_ref.vault_address);

        set_share_table(&mut vault.users_share_in_safety_vault, account);
        set_share_table(&mut vault.users_share_in_risky_vault, account);
    }

    public entry fun close_position_user(_signer: &signer, _collateral_delta: u64, _leverage: u64) {
    }
    
    public entry fun withdraw_risky_vault_with_fee(_signer: &signer, _account: address, _amountClose: u64, _leverage: u64, _amountUnstake:u64, _total_value: u256, _value: u256, _is_negative: bool){
    }

    public entry fun withdraw_safety_with_fee(_signer: &signer, _account: address, _amountClose: u64, _leverage: u64, _amountUnstake:u64, _total_value: u256, _value: u256, _is_negative: bool){
    }
}
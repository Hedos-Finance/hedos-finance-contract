module hedos::general_vault {
    use aptos_framework::table::{Self, Table};
    use aptos_framework::object::{Self, ExtendRef};
    use aptos_framework::event::{emit};

    use hedos::interact_merkle_trade::{simple_trade};
    // use hedos::liquid_actions::{liquid_staking, liquid_staking_unstake, liquid_staking_unstake_all};
    // use hedos::lending_actions::{lending_borrow, lending_deposit, lending_repay, lending_repay_all, lending_withdraw};

    use hedos::liquid_actions::{Self};
    use hedos::lending_actions::{Self};

    use hedos::token::{transfer_usdc, get_usdc_balance};
    
    use std::signer::{Self};
    use std::string::{Self, String};

    use hedos::white_list::{only_admin};

    const HEDOS: address = @hedos;

    struct Vault has key {
        total_value_lock: u64,
        total_share_of_safety_vault: u256,
        total_share_of_risky_vault: u256,
        users_share_in_safety_vault: Table<address, u256>,
        users_share_in_risky_vault: Table<address, u256>,

        total_deposited_risky: u64,
        total_deposited_safety: u64,

        total_perpeptual: u64,
    }

    struct VaultRef has key {
        vault_address: address,
        vault_extend_ref: ExtendRef,
        
        backup_vault_address: address,
        backup_vault_extend_ref: ExtendRef,
    }
    
    struct AdminRef has key {
        admin_address: address,
        admin_extend_ref: ExtendRef,
    }

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
    
    public entry fun init_vault(signer: &signer) acquires VaultRef {
        only_admin(signer);
        let constructor_ref = &object::create_object(HEDOS);
        let vault_signer = &object::generate_signer(constructor_ref);
        let extend_ref = object::generate_extend_ref(constructor_ref);
        let new_vault_address = signer::address_of(vault_signer);

        let new_vault = Vault {
            total_value_lock: 0,
            total_share_of_safety_vault: 0,
            total_share_of_risky_vault: 0,
            users_share_in_safety_vault: table::new<address, u256>(),
            users_share_in_risky_vault: table::new<address, u256>(),
            
            total_deposited_risky: 0,
            total_deposited_safety: 0,

            total_perpeptual: 0
        };
        move_to(vault_signer, new_vault);  
        
        let backup_constructor_ref = &object::create_object(HEDOS);
        let backup_vault_signer = &object::generate_signer(backup_constructor_ref);
        let backup_extend_ref = object::generate_extend_ref(backup_constructor_ref);
        let backup_new_vault_address = signer::address_of(backup_vault_signer); 

        if (!exists<VaultRef>(HEDOS)) {
            move_to(signer, VaultRef {
                vault_address: new_vault_address,
                vault_extend_ref: extend_ref,
                backup_vault_address: backup_new_vault_address,
                backup_vault_extend_ref: backup_extend_ref,
            })
        } else {
            let vault_ref = borrow_global_mut<VaultRef>(HEDOS);
            vault_ref.vault_address = new_vault_address;
            vault_ref.vault_extend_ref = extend_ref;
            vault_ref.backup_vault_address = backup_new_vault_address;
            vault_ref.backup_vault_extend_ref = backup_extend_ref;
        };

        emit(CreateNewVault {
            new_vault_address: new_vault_address
        });
        
        emit(CreateNewVault {
            new_vault_address: backup_new_vault_address
        });
    }

    #[view]
    public fun get_total_perpeptual(): u64 acquires Vault, VaultRef {
        let vault_ref = borrow_global<VaultRef>(HEDOS);
        let vault = borrow_global<Vault>(vault_ref.vault_address);
        vault.total_perpeptual
    }

    public entry fun set_total_perp(signer: &signer, value_perp: u64) acquires Vault, VaultRef {
        only_admin(signer);
        let vault_address = borrow_global<VaultRef>(HEDOS).vault_address;
        let vault = borrow_global_mut<Vault>(vault_address);
        vault.total_perpeptual = value_perp;
    }


    // VAULT ADDRESS
    #[view]
    public fun get_vault_address(): address acquires VaultRef {
        let vault_ref = borrow_global<VaultRef>(HEDOS);
        vault_ref.vault_address
    }

    #[view]
    public fun get_backup_vault_address(): address acquires VaultRef {
        let vault_ref = borrow_global<VaultRef>(HEDOS);
        vault_ref.backup_vault_address
    }
    // =============================

    
    // shares
    #[view]
    public fun user_share(user: address): (u256, u256) acquires Vault, VaultRef {
        let vault_ref = borrow_global<VaultRef>(HEDOS);
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
        let vault_ref = borrow_global<VaultRef>(HEDOS);
        let vault = borrow_global_mut<Vault>(vault_ref.vault_address);

        let safety_total_share = vault.total_share_of_safety_vault;
        let risky_total_share = vault.total_share_of_risky_vault;
        (safety_total_share, risky_total_share)
    }

    fun set_share_table(share_table: &mut Table<address, u256>, account: address) {
        let share = table::borrow_mut_with_default(share_table, account, 0);
        *share = 0;
    }
    
    public entry fun set_total_share(signer: &signer, _risky: u256, _safety: u256) acquires Vault, VaultRef {
        only_admin(signer);
        let vault_ref = borrow_global<VaultRef>(HEDOS);
        let vault = borrow_global_mut<Vault>(vault_ref.vault_address);
        vault.total_share_of_risky_vault = _risky;
        vault.total_share_of_safety_vault = _safety;
    }

    public entry fun set_share_table_user(signer: &signer, account: address) acquires Vault, VaultRef{
        only_admin(signer);
        let vault_ref = borrow_global<VaultRef>(HEDOS);
        let vault = borrow_global_mut<Vault>(vault_ref.vault_address);

        set_share_table(&mut vault.users_share_in_safety_vault, account);
        set_share_table(&mut vault.users_share_in_risky_vault, account);
    }
    // =============================


    // TVL
    #[view]
    public fun current_deposited(): (u64, u64) acquires Vault, VaultRef {
        let vault_ref = borrow_global<VaultRef>(HEDOS);
        let vault = borrow_global<Vault>(vault_ref.vault_address);
        (vault.total_deposited_safety, vault.total_deposited_risky)
    }

    public entry fun set_current(signer: &signer, safety: u64, risky: u64) acquires Vault, VaultRef {
        only_admin(signer);
        let vault_ref = borrow_global<VaultRef>(HEDOS);
        let vault = borrow_global_mut<Vault>(vault_ref.vault_address);
        vault.total_deposited_safety = safety;
        vault.total_deposited_risky = risky;
    }

    public fun update_current_deposited(safety: u64, risky: u64, increase: bool) acquires Vault, VaultRef {
        let vault_ref = borrow_global<VaultRef>(HEDOS);
        let vault = borrow_global_mut<Vault>(vault_ref.vault_address);
        if(increase)
        {   
            vault.total_deposited_safety += safety;
            vault.total_deposited_risky += risky;
        }
        else{
            vault.total_deposited_safety = if (vault.total_deposited_safety >= safety) {
                vault.total_deposited_safety - safety
            } else 0;
            vault.total_deposited_risky = if (vault.total_deposited_risky >= risky) {
                vault.total_deposited_risky - risky
            } else 0;
        }
    }
    
    #[view]
    public fun get_total_value_lock(): u64 acquires Vault, VaultRef {
        let vault_ref = borrow_global<VaultRef>(HEDOS);
        let vault = borrow_global<Vault>(vault_ref.vault_address);
        vault.total_value_lock
    }

    public entry fun set_total_value_lock(signer: &signer, value: u64) acquires Vault, VaultRef {
        only_admin(signer);
        let vault_address = borrow_global<VaultRef>(HEDOS).vault_address;
        let vault = borrow_global_mut<Vault>(vault_address);
        vault.total_value_lock = value;
    }
    // =============================

    // ACTION

    public entry fun open_position(_signer: &signer, collateral_delta: u64, leverage: u64, is_long: bool, market_skew: bool) acquires Vault, VaultRef {
        only_admin(_signer);
        let vault_ref = borrow_global<VaultRef>(HEDOS);
        let vault_signer = &object::generate_signer_for_extending(&vault_ref.vault_extend_ref);
        let backup_vault_signer = &object::generate_signer_for_extending(&vault_ref.backup_vault_extend_ref);

        let pair = get_pair();
        if (!is_long) {
            simple_trade(vault_signer, vault_ref.vault_address, collateral_delta, leverage, is_long, true, market_skew, pair);
        } else {
            transfer_usdc(vault_signer, vault_ref.backup_vault_address, collateral_delta);
            simple_trade(backup_vault_signer, vault_ref.backup_vault_address, collateral_delta, leverage, is_long, true, market_skew, pair);
        };

        let vault = borrow_global_mut<Vault>(vault_ref.vault_address);
        vault.total_perpeptual += collateral_delta;
        emit(OpenPerp {
            collateral_delta,
            leverage,
            pair
        });
    }

    public entry fun close_position(_signer: &signer, collateral_delta: u64, leverage: u64, is_long: bool, market_skew: bool) acquires Vault, VaultRef {
        only_admin(_signer);
        let vault_ref = borrow_global<VaultRef>(HEDOS);
        let vault_signer = &object::generate_signer_for_extending(&vault_ref.vault_extend_ref);
        let backup_vault_signer = &object::generate_signer_for_extending(&vault_ref.backup_vault_extend_ref);

        let pair = get_pair();
        if (!is_long) {
            simple_trade(vault_signer, vault_ref.vault_address, collateral_delta, leverage, is_long, false, market_skew, pair);
        } else {
            simple_trade(backup_vault_signer, vault_ref.backup_vault_address, collateral_delta, leverage, is_long, false, market_skew, pair);
        };

        let vault = borrow_global_mut<Vault>(vault_ref.vault_address);
        
        vault.total_perpeptual = if (vault.total_perpeptual > collateral_delta) {vault.total_perpeptual - collateral_delta} else 0;
        emit(ClosePerp {
            collateral_delta: collateral_delta,
            leverage,
            pair
        });
    }

    
    public entry fun liquid_staking(_signer: &signer, amountUSDC: u64) acquires VaultRef {
        only_admin(_signer);
        let vault_ref = borrow_global<VaultRef>(HEDOS);
        let vault_signer = &object::generate_signer_for_extending(&vault_ref.vault_extend_ref);
        
        liquid_actions::liquid_staking(vault_signer, amountUSDC);

        emit(Stake {
            amount: amountUSDC
        })
    }

    public entry fun liquid_staking_unstake_all(_signer: &signer) acquires VaultRef {
        only_admin(_signer);
        let vault_ref = borrow_global<VaultRef>(HEDOS);
        let vault_signer = &object::generate_signer_for_extending(&vault_ref.vault_extend_ref);
        let usdc_before = get_usdc_balance(vault_ref.vault_address);
        
        liquid_actions::liquid_staking_unstake_all(vault_signer);
        
        let usdc_after = get_usdc_balance(vault_ref.vault_address);

        let amount_unstake = usdc_after - usdc_before;
       
        emit(UnStake {
            amount: amount_unstake
        })
    }
    public entry fun liquid_staking_unstake(_signer: &signer, amountUSDC: u64) acquires VaultRef {
        only_admin(_signer);
        let vault_ref = borrow_global<VaultRef>(HEDOS);
        let vault_signer = &object::generate_signer_for_extending(&vault_ref.vault_extend_ref);
        let usdc_before = get_usdc_balance(vault_ref.vault_address);

        liquid_actions::liquid_staking_unstake(vault_signer, amountUSDC);

        let usdc_after = get_usdc_balance(vault_ref.vault_address);

        let amount_unstake = usdc_after - usdc_before;
        
        emit(UnStake {
            amount: amount_unstake
        })
    }

    
    public entry fun lending_deposit(_signer: &signer, amount: u64, token: String) acquires VaultRef {
        only_admin(_signer);
        let vault_ref = borrow_global<VaultRef>(HEDOS);
        let vault_signer = &object::generate_signer_for_extending(&vault_ref.vault_extend_ref);

        lending_actions::lending_deposit(vault_signer, amount, token);

        emit(DepositLending {
            amount: amount,
            token: token
        });
    }

    public entry fun lending_borrow(_signer: &signer, amountAPT: u64) acquires VaultRef {
        only_admin(_signer);
        let vault_ref = borrow_global<VaultRef>(HEDOS);
        let vault_signer = &object::generate_signer_for_extending(&vault_ref.vault_extend_ref);

        
        lending_actions::lending_borrow(vault_signer, amountAPT);

        emit(BorrowLending {
            amount: amountAPT,
            token: stringAPT()
        });
    }
    
    public entry fun lending_repay(_signer: &signer, amountAPT: u64) acquires VaultRef {
        only_admin(_signer);
        let vault_ref = borrow_global<VaultRef>(HEDOS);
        let vault_signer = &object::generate_signer_for_extending(&vault_ref.vault_extend_ref);

        lending_actions::lending_repay(vault_signer, amountAPT);

        emit(RepayLending {
            amount: amountAPT,
            token: stringAPT()
        });
    }
    
    public entry fun lending_withdraw(_signer: &signer, amount: u64, token: String) acquires VaultRef {
        only_admin(_signer);
        let vault_ref = borrow_global<VaultRef>(HEDOS);
        let vault_signer = &object::generate_signer_for_extending(&vault_ref.vault_extend_ref);

        lending_actions::lending_withdraw(vault_signer, amount, token);

        emit(WithdrawLending {
            amount: amount,
            token: token
        });
    }
}
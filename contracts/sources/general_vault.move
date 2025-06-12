module delta_hedging::general_vault {
    // use std::string::String;
    // use aptos_framework::aptos_account::{Self, transfer_fungible_assets};
    // use aptos_framework::coin::{Self, Coin};
    use aptos_framework::table::{Self, Table};
    use aptos_framework::event::{emit};
    use aptos_framework::object::{Self, ExtendRef};

    use std::signer::{Self};

    use delta_hedging::math::{I64, init_i64, get_value, is_negative, add, sub};
    use delta_hedging::white_list::{only_admin};
    use delta_hedging::token::{transfer_usdc};

    const DELTA_HEDGING: address = @delta_hedging;

    const NOT_ENOUGH_SHARE: u64 = 997;

    #[event]
    struct CreateNewVault has drop, store {
        new_vault_address: address
    }

    struct Vault has key {
        total_share_of_safety_vault: u64,
        users_share_in_safety_vault: Table<address, u64>,
        total_share_of_risky_vault: u64,
        users_share_in_risky_vault: Table<address, u64>,

        fund_fee: I64,
        fund_fee_risky_rate_numerator: u64,
        fund_fee_risky_rate_denominator: u64, 
    }

    struct VaultRef has key {
        vault_address: address,
        vault_extend_ref: ExtendRef,
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

    public entry fun init_vault(signer: &signer) acquires VaultRef {
        only_admin(signer);

        let constructor_ref = &object::create_object(DELTA_HEDGING);
        let vault_signer = &object::generate_signer(constructor_ref);
        let extend_ref = object::generate_extend_ref(constructor_ref);
        let new_vault_address = signer::address_of(vault_signer);

        let new_vault = Vault {
            total_share_of_safety_vault: 0,
            total_share_of_risky_vault: 0,
            users_share_in_safety_vault: table::new<address, u64>(),
            users_share_in_risky_vault: table::new<address, u64>(),
            fund_fee: init_i64(0, false),
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

    fun update_share_table(share_table: &mut Table<address, u64>, account: address, delta_share: u64, increase: bool) {
        let share = table::borrow_mut_with_default(share_table, account, 0);
        
        if (increase) {
            *share += delta_share;
        } else {
            assert!(*share >= delta_share, NOT_ENOUGH_SHARE);
            *share -= delta_share;
        };
    }

    public entry fun deposit_risky_vault(signer: &signer, account: address, amount: u64, total_value: u64) acquires Vault, VaultRef {
        let vault_ref = borrow_global<VaultRef>(DELTA_HEDGING);
        let vault = borrow_global_mut<Vault>(vault_ref.vault_address);

        let total_share = vault.total_share_of_risky_vault + vault.total_share_of_safety_vault;
        let user_share = total_share * amount / total_value;

        update_share_table(&mut vault.users_share_in_risky_vault, account, user_share, true);
        vault.total_share_of_risky_vault += user_share;

        transfer_usdc(signer, DELTA_HEDGING, amount);

        emit(Deposited {
            account,
            amount,
            is_risky: true,
        });
    }

    public entry fun deposit_safety_vault(signer: &signer, account: address, amount: u64, total_value: u64) acquires Vault, VaultRef {
        let vault_ref = borrow_global<VaultRef>(DELTA_HEDGING);
        let vault = borrow_global_mut<Vault>(vault_ref.vault_address);

        let total_share = vault.total_share_of_risky_vault + vault.total_share_of_safety_vault;
        let user_share = total_share * amount / total_value;

        update_share_table(&mut vault.users_share_in_safety_vault, account, user_share, true);
        vault.total_share_of_safety_vault += user_share;

        transfer_usdc(signer, DELTA_HEDGING, amount);
        
        emit(Deposited {
            account,
            amount,
            is_risky: false,
        });
    }

    public entry fun withdraw_risky_vault(signer: &signer, account: address, amount: u64, total_value: u64) acquires Vault, VaultRef {
        let vault_ref = borrow_global<VaultRef>(DELTA_HEDGING);
        let vault = borrow_global_mut<Vault>(vault_ref.vault_address);

        let total_share = vault.total_share_of_risky_vault + vault.total_share_of_safety_vault;
        let user_share = total_share * amount / total_value;

        update_share_table(&mut vault.users_share_in_risky_vault, account, user_share, false);
        vault.total_share_of_risky_vault -= user_share;

        // TODO: update interact with stake&perp

        let vault_signer = &object::generate_signer_for_extending(&vault_ref.vault_extend_ref);
        transfer_usdc(vault_signer, account, amount);

        emit(Withdrawn {
            account,
            amount,
            is_risky: true,
        });
    }

    public entry fun withdraw_safety_vault(signer: &signer, account: address, amount: u64, total_value: u64) acquires Vault, VaultRef {
        let vault_ref = borrow_global<VaultRef>(DELTA_HEDGING);
        let vault = borrow_global_mut<Vault>(vault_ref.vault_address);

        let total_share = vault.total_share_of_risky_vault + vault.total_share_of_safety_vault;
        let user_share = total_share * amount / total_value;

        update_share_table(&mut vault.users_share_in_safety_vault, account, user_share, false);
        vault.total_share_of_safety_vault -= user_share;

        // TODO: update interact with stake&perp
        
        let vault_signer = &object::generate_signer_for_extending(&vault_ref.vault_extend_ref);
        transfer_usdc(vault_signer, account, amount);

        emit(Withdrawn {
            account,
            amount,
            is_risky: false,
        });
    }

    fun fund_fee_risky(): I64 acquires Vault, VaultRef {
        let vault_address = borrow_global<VaultRef>(DELTA_HEDGING).vault_address;
        let fund_fee = borrow_global<Vault>(vault_address).fund_fee;
        let risky_rate_numerator = borrow_global<Vault>(vault_address).fund_fee_risky_rate_numerator;
        let risky_rate_denominator = borrow_global<Vault>(vault_address).fund_fee_risky_rate_denominator;

        let fund_fee_risky = init_i64(get_value(fund_fee) * risky_rate_denominator / risky_rate_numerator, is_negative(fund_fee));

        fund_fee_risky
    }

    fun fund_fee_after_risky(): I64 acquires Vault, VaultRef {
        let vault_address = borrow_global<VaultRef>(DELTA_HEDGING).vault_address;
        let fund_fee = borrow_global<Vault>(vault_address).fund_fee;
        let fund_fee_after_risky = fund_fee_risky();

        sub(fund_fee, fund_fee_after_risky)
    }

    fun calc_fund_fee(
        _fund_fee: I64,
        _user_share: u64,
        _total_share: u64,
    ): I64 {
        let result: u64 = get_value(_fund_fee) * _user_share / _total_share;
        let is_negative: bool = false;

        init_i64(result, is_negative)
    }

    public fun total_fund_fee_in_risky_vault(): I64 acquires Vault, VaultRef {
        let fund_fee_after_risky = fund_fee_after_risky();
        let fund_fee_risky = fund_fee_risky();
        
        let vault_address = borrow_global<VaultRef>(DELTA_HEDGING).vault_address;
        let safety_vault = borrow_global<Vault>(vault_address).total_share_of_safety_vault;
        let risky_vault = borrow_global<Vault>(vault_address).total_share_of_risky_vault;
    
        let result = get_value(fund_fee_risky) + get_value(fund_fee_after_risky) * risky_vault / (safety_vault + risky_vault);
        let is_negative = is_negative(fund_fee_risky);

        init_i64(result, is_negative)
    }

    public fun total_fund_fee_in_safety_vault(): u64 acquires Vault, VaultRef {
        let result: u64 = 0;
        let vault_address = borrow_global<VaultRef>(DELTA_HEDGING).vault_address;
        let fund_fee = borrow_global<Vault>(vault_address).fund_fee;

        if (!is_negative(fund_fee)) {
            let safety_vault = borrow_global<Vault>(vault_address).total_share_of_safety_vault;
            let risky_vault = borrow_global<Vault>(vault_address).total_share_of_risky_vault;
            
            let fund_fee_after_risky = fund_fee_after_risky();
            result = get_value(fund_fee_after_risky) * safety_vault / (safety_vault + risky_vault);
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

    public entry fun set_fund_fee(signer: &signer, value: u64, is_negative: bool) acquires Vault, VaultRef {
        only_admin(signer);
        let vault_address = borrow_global<VaultRef>(DELTA_HEDGING).vault_address;
        let vault = borrow_global_mut<Vault>(vault_address);
        vault.fund_fee = init_i64(value, is_negative);
    }
}
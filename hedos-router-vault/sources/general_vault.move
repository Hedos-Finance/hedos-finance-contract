module hedos::general_vault {
    // use aptos_framework::table::{Self, Table};
    use aptos_framework::object::{Self, ExtendRef};
    use aptos_framework::event::{emit};

    use aptos_framework::timestamp::{now_seconds};

    use hedos::token::{transfer_usdc, get_usdc_balance};

    use hedos::shares_token;

    use std::signer::{Self};

    use hedos::white_list::{only_admin};

    const HEDOS: address = @hedos;

    struct Vault has key {
        total_value_lock: u64,
        total_deposited_risky: u64,
        total_deposited_safety: u64
    }

    struct VaultRef has key {
        vault_address: address,
        vault_extend_ref: ExtendRef
    }

    struct InteractAdress has key {
        lending_vault: address,
        staking_vault: address,
        perp_vault: address
    }

    struct AdminRef has key {
        admin_address: address,
        admin_extend_ref: ExtendRef
    }

    struct ReservePool has key {}

    struct ReservePoolRef has key {
        vault_address: address,
        vault_extend_ref: ExtendRef
    }

    struct Nonce has key {
        current_nonce: u64
    }

    struct RewardPool has key {
        risky_balance: u64,
        safety_balance: u64
    }

    struct RewardPoolRef has key {
        vault_address: address,
        vault_extend_ref: ExtendRef
    }

    #[event]
    struct CreateNewVault has drop, store {
        new_vault_address: address
    }

    #[event]
    struct Deposited has drop, store {
        account: address,
        amount: u64,
        is_risky: bool
    }

    #[event]
    struct Withdraw has drop, store {
        account: address,
        amount: u64,
        is_risky: bool
    }

    public entry fun init_vault(signer: &signer) {
        only_admin(signer);
        let constructor_ref = &object::create_object(HEDOS);
        let vault_signer = &object::generate_signer(constructor_ref);
        let extend_ref = object::generate_extend_ref(constructor_ref);
        let new_vault_address = signer::address_of(vault_signer);

        let new_vault = Vault {
            total_value_lock: 0,
            total_deposited_risky: 0,
            total_deposited_safety: 0
        };
        move_to(vault_signer, new_vault);

        if (!exists<VaultRef>(HEDOS)) {
            move_to(
                signer,
                VaultRef { vault_address: new_vault_address, vault_extend_ref: extend_ref }
            )
        };

        emit(CreateNewVault { new_vault_address });
    }

    // VAULT ADDRESS
    #[view]
    public fun get_vault_address(): address acquires VaultRef {
        let vault_ref = borrow_global<VaultRef>(HEDOS);
        vault_ref.vault_address
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

    public fun update_current_deposited(
        _safety: u64, _risky: u64, _increase: bool
    ) {}

    fun update_current_deposited_internal(
        safety: u64, risky: u64, increase: bool
    ) acquires Vault, VaultRef {
        let vault_ref = borrow_global<VaultRef>(HEDOS);
        let vault = borrow_global_mut<Vault>(vault_ref.vault_address);
        if (increase) {
            vault.total_deposited_safety += safety;
            vault.total_deposited_risky += risky;
        } else {
            vault.total_deposited_safety =
                if (vault.total_deposited_safety >= safety) {
                    vault.total_deposited_safety - safety
                } else 0;
            vault.total_deposited_risky =
                if (vault.total_deposited_risky >= risky) {
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

    // Reserve Pool
    public entry fun init_reserve_pool(signer: &signer) {
        only_admin(signer);
        let constructor_ref = &object::create_object(HEDOS);
        let vault_signer = &object::generate_signer(constructor_ref);
        let extend_ref = object::generate_extend_ref(constructor_ref);
        let new_vault_address = signer::address_of(vault_signer);

        let new_vault = ReservePool {};

        move_to(vault_signer, new_vault);

        if (!exists<ReservePoolRef>(HEDOS)) {
            move_to(
                signer,
                ReservePoolRef {
                    vault_address: new_vault_address,
                    vault_extend_ref: extend_ref
                }
            )
        };
    }

    #[view]
    public fun get_reserve_pool_address(): address acquires ReservePoolRef {
        let reserve_pool_ref = borrow_global<ReservePoolRef>(HEDOS);
        reserve_pool_ref.vault_address
    }

    public entry fun deposit_to_reserve_pool(
        signer: &signer, amountUSDC: u64
    ) acquires VaultRef, ReservePoolRef {
        only_admin(signer);
        let vault_ref = borrow_global<VaultRef>(HEDOS);
        let vault_signer =
            &object::generate_signer_for_extending(&vault_ref.vault_extend_ref);
        let reserve_pool_ref = borrow_global<ReservePoolRef>(HEDOS);
        let reserve_pool_address = reserve_pool_ref.vault_address;
        transfer_usdc(vault_signer, reserve_pool_address, amountUSDC);
    }

    public entry fun transfer_from_reserve_pool(
        signer: &signer, amountUSDC: u64
    ) acquires VaultRef, ReservePoolRef {
        only_admin(signer);
        let vault_ref = borrow_global<VaultRef>(HEDOS);
        let vault_address = vault_ref.vault_address;

        let reserve_pool_ref = borrow_global<ReservePoolRef>(HEDOS);
        let reserve_pool_signer =
            &object::generate_signer_for_extending(&reserve_pool_ref.vault_extend_ref);

        transfer_usdc(reserve_pool_signer, vault_address, amountUSDC);
    }

    // =============================

    // Reward Pool
    public entry fun init_reward_pool(signer: &signer) {
        only_admin(signer);
        let constructor_ref = &object::create_object(HEDOS);
        let vault_signer = &object::generate_signer(constructor_ref);
        let extend_ref = object::generate_extend_ref(constructor_ref);
        let new_vault_address = signer::address_of(vault_signer);

        let new_vault = RewardPool { risky_balance: 0, safety_balance: 0 };

        move_to(vault_signer, new_vault);

        if (!exists<RewardPoolRef>(HEDOS)) {
            move_to(
                signer,
                RewardPoolRef {
                    vault_address: new_vault_address,
                    vault_extend_ref: extend_ref
                }
            )
        };
    }

    #[view]
    public fun get_reward_pool_address(): address acquires RewardPoolRef {
        let reward_pool_ref = borrow_global<RewardPoolRef>(HEDOS);
        reward_pool_ref.vault_address
    }

    public entry fun deposit_to_reward_pool(
        signer: &signer, amountUSDC: u64
    ) acquires VaultRef, RewardPoolRef {
        only_admin(signer);
        let reward_pool_ref = borrow_global<RewardPoolRef>(HEDOS);
        let reward_pool_address = reward_pool_ref.vault_address;
        let vault_ref = borrow_global<VaultRef>(HEDOS);
        let vault_signer =
            &object::generate_signer_for_extending(&vault_ref.vault_extend_ref);
        transfer_usdc(vault_signer, reward_pool_address, amountUSDC);
    }

    public entry fun transfer_from_reward_pool(
        signer: &signer, amountUSDC: u64
    ) acquires VaultRef, RewardPoolRef {
        only_admin(signer);
        let vault_ref = borrow_global<VaultRef>(HEDOS);
        let vault_address = vault_ref.vault_address;

        let reward_pool_ref = borrow_global<RewardPoolRef>(HEDOS);
        let reward_pool_signer =
            &object::generate_signer_for_extending(&reward_pool_ref.vault_extend_ref);

        transfer_usdc(reward_pool_signer, vault_address, amountUSDC);
    }

    #[view]
    public fun get_reward_balance(): (u64, u64) acquires RewardPool, RewardPoolRef {
        let reward_pool_address = borrow_global<RewardPoolRef>(HEDOS).vault_address;
        let reward_pool = borrow_global<RewardPool>(reward_pool_address);

        (reward_pool.safety_balance, reward_pool.risky_balance)
    }

    public entry fun set_reward_balance(
        signer: &signer, safety: u64, risky: u64
    ) acquires RewardPool, RewardPoolRef {
        only_admin(signer);

        let reward_pool_address = borrow_global<RewardPoolRef>(HEDOS).vault_address;
        let reward_pool = borrow_global_mut<RewardPool>(reward_pool_address);

        reward_pool.safety_balance = safety;
        reward_pool.risky_balance = risky;
    }

    // fun update_reward_balance(safety: u64, risky: u64, increase: bool) acquires RewardPool, RewardPoolRef {

    //     let reward_pool_address = borrow_global<RewardPoolRef>(HEDOS).vault_address;
    //     let reward_pool = borrow_global_mut<RewardPool>(reward_pool_address);

    //     if (increase) {
    //         reward_pool.safety_balance += safety;
    //         reward_pool.risky_balance += risky;
    //     } else {
    //         reward_pool.safety_balance -= safety;
    //         reward_pool.risky_balance -= risky;
    //     }
    // }

    public entry fun update_reward_vault(
        _signer: &signer,
        safety: u64,
        risky: u64,
        increase: bool
    ) acquires Vault, VaultRef, RewardPool, RewardPoolRef {
        only_admin(_signer);
        let (safety_balance, risky_balance) = get_reward_balance();
        let reward_pool_address = borrow_global<RewardPoolRef>(HEDOS).vault_address;
        let reward_pool = borrow_global_mut<RewardPool>(reward_pool_address);

        if (increase) {
            deposit_to_reward_pool(_signer, safety + risky);
            reward_pool.safety_balance += safety;
            reward_pool.risky_balance += risky;
        } else {
            if (safety_balance < safety) {
                update_current_deposited_internal(safety - safety_balance, 0, false);
                safety = safety_balance;
            };
            if (risky_balance < risky) {
                update_current_deposited_internal(0, risky - risky_balance, false);
                risky = risky_balance;
            };
            transfer_from_reward_pool(_signer, safety + risky);
            reward_pool.safety_balance -= safety;
            reward_pool.risky_balance -= risky;
        }
    }

    // =============================

    // Interact Address

    public entry fun init_interact_address(
        signer: &signer,
        lending: address,
        liquid: address,
        perp: address
    ) {
        only_admin(signer);

        if (!exists<InteractAdress>(HEDOS)) {
            move_to(
                signer,
                InteractAdress {
                    lending_vault: lending,
                    staking_vault: liquid,
                    perp_vault: perp
                }
            );
        };
    }

    #[view]
    public fun get_lending_vault_address(): address acquires InteractAdress {
        let storage = borrow_global<InteractAdress>(HEDOS);
        storage.lending_vault
    }

    #[view]
    public fun get_staking_vault_address(): address acquires InteractAdress {
        let storage = borrow_global<InteractAdress>(HEDOS);
        storage.staking_vault
    }

    #[view]
    public fun get_perp_vault_address(): address acquires InteractAdress {
        let storage = borrow_global<InteractAdress>(HEDOS);
        storage.perp_vault
    }

    public entry fun set_lending_vault_address(
        signer: &signer, address: address
    ) acquires InteractAdress {
        only_admin(signer);
        let storage = borrow_global_mut<InteractAdress>(HEDOS);
        storage.lending_vault = address;
    }

    public entry fun set_staking_vault_address(
        signer: &signer, address: address
    ) acquires InteractAdress {
        only_admin(signer);
        let storage = borrow_global_mut<InteractAdress>(HEDOS);
        storage.staking_vault = address;
    }

    public entry fun set_perp_vault_address(
        signer: &signer, address: address
    ) acquires InteractAdress {
        only_admin(signer);
        let storage = borrow_global_mut<InteractAdress>(HEDOS);
        storage.perp_vault = address;
    }

    public entry fun send_to_lending_vault(
        signer: &signer, amount: u64
    ) acquires VaultRef, InteractAdress {
        only_admin(signer);
        let vault_ref = borrow_global<VaultRef>(HEDOS);
        let lending_vault_address = borrow_global<InteractAdress>(HEDOS).lending_vault;
        let vault_signer =
            &object::generate_signer_for_extending(&vault_ref.vault_extend_ref);
        transfer_usdc(vault_signer, lending_vault_address, amount);
    }

    public entry fun send_to_staking_vault(
        signer: &signer, amount: u64
    ) acquires VaultRef, InteractAdress {
        only_admin(signer);
        let vault_ref = borrow_global<VaultRef>(HEDOS);
        let staking_vault_address = borrow_global<InteractAdress>(HEDOS).staking_vault;
        let vault_signer =
            &object::generate_signer_for_extending(&vault_ref.vault_extend_ref);
        transfer_usdc(vault_signer, staking_vault_address, amount);
    }

    public entry fun send_to_perp_vault(signer: &signer, amount: u64) acquires VaultRef, InteractAdress {
        only_admin(signer);
        let vault_ref = borrow_global<VaultRef>(HEDOS);
        let perp_vault_address = borrow_global<InteractAdress>(HEDOS).perp_vault;
        let vault_signer =
            &object::generate_signer_for_extending(&vault_ref.vault_extend_ref);
        transfer_usdc(vault_signer, perp_vault_address, amount);
    }

    // =============================

    #[view]
    public fun get_next_nonce(): u64 acquires Nonce {
        if (!exists<Nonce>(HEDOS)) { 0 }
        else {
            let nonce = borrow_global<Nonce>(HEDOS);
            nonce.current_nonce + 1
        }
    }

    fun increase_nonce() acquires Nonce {
        let nonce = borrow_global_mut<Nonce>(HEDOS);
        nonce.current_nonce += 1;
    }

    public entry fun init_nonce(signer: &signer) {
        only_admin(signer);
        if (!exists<Nonce>(HEDOS)) {
            move_to(signer, Nonce { current_nonce: 0 });
        }
    }

    /// nonce is invalid
    const INVALID_NONCE: u64 = 990;
    /// timestamp is invalid
    const INVALID_TIMESTAMP: u64 = 989;

    // User Actions
    public entry fun deposit_risky_vault(signer: &signer, amount: u64) acquires Vault, VaultRef {
        let vault_ref = borrow_global<VaultRef>(HEDOS);
        let vault = borrow_global_mut<Vault>(vault_ref.vault_address);

        let account = signer::address_of(signer);

        vault.total_value_lock += amount;
        vault.total_deposited_risky += amount;

        transfer_usdc(signer, vault_ref.vault_address, amount);

        emit(Deposited { account, amount, is_risky: true });
    }

    public entry fun deposit_safety_vault(signer: &signer, amount: u64) acquires Vault, VaultRef {
        let vault_ref = borrow_global<VaultRef>(HEDOS);
        let vault = borrow_global_mut<Vault>(vault_ref.vault_address);

        let account = signer::address_of(signer);

        vault.total_value_lock += amount;
        vault.total_deposited_safety += amount;

        transfer_usdc(signer, vault_ref.vault_address, amount);

        emit(Deposited { account, amount, is_risky: false });
    }

    public entry fun multiagent_deposit_risky_vault(
        signer: &signer,
        admin: &signer,
        amount: u64,
        total_value: u64,
        nonce: u64,
        timestamp: u64
    ) acquires Vault, VaultRef, Nonce {
        only_admin(admin);
        let next_nonce = get_next_nonce();

        assert!(nonce == next_nonce, INVALID_NONCE);
        assert!(now_seconds() <= timestamp, INVALID_TIMESTAMP);

        increase_nonce();
        deposit_risky_vault(signer, amount);
        mint_risky(
            admin,
            signer::address_of(signer),
            amount,
            total_value
        );
    }

    public entry fun multiagent_deposit_safety_vault(
        signer: &signer,
        admin: &signer,
        amount: u64,
        total_value: u64,
        nonce: u64,
        timestamp: u64
    ) acquires Vault, VaultRef, Nonce {
        only_admin(admin);
        let next_nonce = get_next_nonce();

        assert!(nonce == next_nonce, INVALID_NONCE);
        assert!(now_seconds() <= timestamp, INVALID_TIMESTAMP);

        increase_nonce();
        deposit_safety_vault(signer, amount);
        mint_safety(
            admin,
            signer::address_of(signer),
            amount,
            total_value
        );
    }

    public entry fun mint_risky(
        admin: &signer,
        account: address,
        amount: u64,
        total_value: u64
    ) {
        only_admin(admin);

        let user_share: u128;
        let total_share = shares_token::get_total_risky_supply();

        if (total_share == 0) {
            user_share = (amount as u128) * 1_000_000;
        } else user_share = (total_share * (amount as u128)) / (total_value as u128);

        shares_token::mint_risky(admin, account, user_share as u64);
    }

    public entry fun mint_safety(
        admin: &signer,
        account: address,
        amount: u64,
        total_value: u64
    ) {
        only_admin(admin);

        let user_share: u128;
        let total_share = shares_token::get_total_safety_supply();

        if (total_share == 0) {
            user_share = (amount as u128) * 1_000_000;
        } else user_share = (total_share * (amount as u128)) / (total_value as u128);

        shares_token::mint_safety(admin, account, user_share as u64);
    }

    public entry fun withdraw_risky_vault(signer: &signer, shares: u64) acquires VaultRef {
        let account = signer::address_of(signer);

        shares_token::transfer_risky(signer, get_vault_address(), shares);

        emit(Withdraw { account, amount: shares, is_risky: true });
    }

    public entry fun withdraw_safety_vault(signer: &signer, shares: u64) acquires VaultRef {
        let account = signer::address_of(signer);

        shares_token::transfer_safety(signer, get_vault_address(), shares);

        emit(Withdraw { account, amount: shares, is_risky: false });
    }

    public entry fun burn_risky(
        admin: &signer,
        account: address,
        amount: u64,
        shares: u64
    ) acquires Vault, VaultRef {
        only_admin(admin);

        let vault_ref = borrow_global<VaultRef>(HEDOS);
        let vault = borrow_global_mut<Vault>(vault_ref.vault_address);
        let vault_signer =
            &object::generate_signer_for_extending(&vault_ref.vault_extend_ref);

        vault.total_value_lock -= amount;
        vault.total_deposited_risky -= amount;

        let usdc_balance = get_usdc_balance(vault_ref.vault_address);
        if (usdc_balance < amount) {
            amount = usdc_balance;
        };

        shares_token::burn_risky(admin, get_vault_address(), shares);

        transfer_usdc(vault_signer, account, amount);
    }

    public entry fun burn_safety(
        admin: &signer,
        account: address,
        amount: u64,
        shares: u64
    ) acquires Vault, VaultRef {
        only_admin(admin);

        let vault_ref = borrow_global<VaultRef>(HEDOS);
        let vault = borrow_global_mut<Vault>(vault_ref.vault_address);
        let vault_signer =
            &object::generate_signer_for_extending(&vault_ref.vault_extend_ref);

        vault.total_value_lock -= amount;
        vault.total_deposited_safety -= amount;

        let usdc_balance = get_usdc_balance(vault_ref.vault_address);
        if (usdc_balance < amount) {
            amount = usdc_balance;
        };

        shares_token::burn_safety(admin, get_vault_address(), shares);

        transfer_usdc(vault_signer, account, amount);
    }

    public entry fun revert_risky(
        admin: &signer, account: address, shares: u64
    ) acquires VaultRef {
        only_admin(admin);

        let vault_ref = borrow_global<VaultRef>(HEDOS);
        let vault_signer =
            &object::generate_signer_for_extending(&vault_ref.vault_extend_ref);

        shares_token::transfer_risky(vault_signer, account, shares);
    }

    public entry fun revert_safety(
        admin: &signer, account: address, shares: u64
    ) acquires VaultRef {
        only_admin(admin);

        let vault_ref = borrow_global<VaultRef>(HEDOS);
        let vault_signer =
            &object::generate_signer_for_extending(&vault_ref.vault_extend_ref);

        shares_token::transfer_safety(vault_signer, account, shares);
    }

    public entry fun admin_withdraw(signer: &signer, amount: u64) acquires VaultRef {
        only_admin(signer);
        let vault_ref = borrow_global<VaultRef>(HEDOS);
        let vault_signer =
            &object::generate_signer_for_extending(&vault_ref.vault_extend_ref);
        transfer_usdc(vault_signer, signer::address_of(signer), amount);
    }
}


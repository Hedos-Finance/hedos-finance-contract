module hedos::general_vault {
    // use aptos_framework::table::{Self, Table};
    use aptos_framework::object::{Self, ExtendRef};
    use aptos_framework::event::{emit};

    use hedos::token::{transfer_usdc};
    
    use std::signer::{Self};

    use hedos::white_list::{only_admin};

    const HEDOS: address = @hedos;

    struct Vault has key {
        total_value_lock: u64,

        total_deposited_risky: u64,
        total_deposited_safety: u64,
    }

    struct VaultRef has key {
        vault_address: address,
        vault_extend_ref: ExtendRef,
    }

    struct InteractAdress has key {
        lending_vault: address,
        staking_vault: address,
        perp_vault: address,
    }
    
    struct AdminRef has key {
        admin_address: address,
        admin_extend_ref: ExtendRef,
    }

    #[event]
    struct CreateNewVault has drop, store {
        new_vault_address: address
    }
    
    #[event]
    struct Deposited has drop, store {
        account: address,
        amount: u64,
        is_risky: bool,
    }

    #[event]
    struct Withdraw has drop, store {
        account: address,
        amount: u64,
        is_risky: bool,
    }
    
    public entry fun init_vault(signer: &signer) acquires VaultRef {
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
        
        // let backup_constructor_ref = &object::create_object(HEDOS);
        // let backup_vault_signer = &object::generate_signer(backup_constructor_ref);
        // let backup_extend_ref = object::generate_extend_ref(backup_constructor_ref);
        // let backup_new_vault_address = signer::address_of(backup_vault_signer); 

        if (!exists<VaultRef>(HEDOS)) {
            move_to(signer, VaultRef {
                vault_address: new_vault_address,
                vault_extend_ref: extend_ref,
                // backup_vault_address: backup_new_vault_address,
                // backup_vault_extend_ref: backup_extend_ref,
            })
        } else {
            let vault_ref = borrow_global_mut<VaultRef>(HEDOS);
            vault_ref.vault_address = new_vault_address;
            vault_ref.vault_extend_ref = extend_ref;
            // vault_ref.backup_vault_address = backup_new_vault_address;
            // vault_ref.backup_vault_extend_ref = backup_extend_ref;
        };

        emit(CreateNewVault {
            new_vault_address: new_vault_address
        });
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


    // Interact Address
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

    public entry fun set_lending_vault_address(signer: &signer, address: address) acquires InteractAdress {
        only_admin(signer);
        let storage = borrow_global_mut<InteractAdress>(HEDOS);
        storage.lending_vault = address;
    }
    public entry fun set_staking_vault_address(signer: &signer, address: address) acquires InteractAdress {
        only_admin(signer);
        let storage = borrow_global_mut<InteractAdress>(HEDOS);
        storage.staking_vault = address;
    }
    public entry fun set_perp_vault_address(signer: &signer, address: address) acquires InteractAdress {
        only_admin(signer);
        let storage = borrow_global_mut<InteractAdress>(HEDOS);
        storage.perp_vault = address;
    }

    public entry fun send_to_lending_vault(signer: &signer, amount: u64) acquires VaultRef, InteractAdress {
        only_admin(signer);
        let vault_ref = borrow_global<VaultRef>(HEDOS);
        let lending_vault_address = borrow_global<InteractAdress>(HEDOS).lending_vault;
        let vault_signer = &object::generate_signer_for_extending(&vault_ref.vault_extend_ref);
        transfer_usdc(vault_signer, lending_vault_address, amount);
    }

    public entry fun send_to_staking_vault(signer: &signer, amount: u64) acquires VaultRef, InteractAdress {
        only_admin(signer);
        let vault_ref = borrow_global<VaultRef>(HEDOS);
        let staking_vault_address = borrow_global<InteractAdress>(HEDOS).staking_vault;
        let vault_signer = &object::generate_signer_for_extending(&vault_ref.vault_extend_ref);
        transfer_usdc(vault_signer, staking_vault_address, amount);
    }

    public entry fun send_to_perp_vault(signer: &signer, amount: u64) acquires VaultRef, InteractAdress {
        only_admin(signer);
        let vault_ref = borrow_global<VaultRef>(HEDOS);
        let perp_vault_address = borrow_global<InteractAdress>(HEDOS).perp_vault;
        let vault_signer = &object::generate_signer_for_extending(&vault_ref.vault_extend_ref);
        transfer_usdc(vault_signer, perp_vault_address, amount);
    }
    // =============================


    // User Actions
    public entry fun deposit_risky_vault(signer: &signer, amount: u64) acquires Vault, VaultRef {
        let vault_ref = borrow_global<VaultRef>(HEDOS);
        let vault = borrow_global_mut<Vault>(vault_ref.vault_address);

        let account = signer::address_of(signer);

        vault.total_value_lock += amount;
        vault.total_deposited_risky += amount;

        transfer_usdc(signer, vault_ref.vault_address, amount);

        emit(Deposited {
            account,
            amount,
            is_risky: true,
        });
    }

    public entry fun deposit_safety_vault(signer: &signer, amount: u64) acquires Vault, VaultRef {
        let vault_ref = borrow_global<VaultRef>(HEDOS);
        let vault = borrow_global_mut<Vault>(vault_ref.vault_address);

        let account = signer::address_of(signer);

        vault.total_value_lock += amount;
        vault.total_deposited_safety += amount;

        transfer_usdc(signer, vault_ref.vault_address, amount);

        emit(Deposited {
            account,
            amount,
            is_risky: false,
        });
    }

    public entry fun withdraw_risky_vault(signer: &signer, amount: u64) {
        let account = signer::address_of(signer);
        emit(Withdraw {
            account,
            amount,
            is_risky: true,
        });
    }

    public entry fun withdraw_safety_vault(signer: &signer, amount: u64) {
        let account = signer::address_of(signer);
        emit(Withdraw {
            account,
            amount,
            is_risky: false,
        });
    }
}

module hedos::liquid_actions {
    use aptos_framework::object::{Self, ExtendRef};
    use aptos_framework::event::{emit};

    use hedos::token::{get_apt_balance, get_amAPT_balance, get_stAPT_balance, transfer_usdc, get_usdc_balance};
    use hedos::interact_hyperion::{hyperion_swap_X_To_Y, get_amount_in, get_X_to_Y_out};
    use hedos::interact_amnis::{stake, unstake_amAPT, price_stAPT};
    use hedos::white_list::{only_admin};

    const HEDOS: address = @hedos;

    use hedos::general_vault::{get_vault_address, send_to_staking_vault};
    
    use std::signer;
    use std::string::{String, utf8};

    const USDC_CHOOSEN: u8 = 1;
    const APT_CHOOSEN: u8 = 2;
    const AMAPT_CHOOSEN: u8 = 3;

    const PRECISION: u128 = 100000000;

    #[event]
    struct CreateNewVault has drop, store {
        new_vault_address: address
    }

    struct LiquidVault has key {
    }

    struct LiquidVaultRef has key {
        vault_address: address,
        vault_extend_ref: ExtendRef,
    }

    #[view]
    public fun get_liquid_vault_address(): address acquires LiquidVaultRef {
        let vault_ref = borrow_global<LiquidVaultRef>(HEDOS);
        vault_ref.vault_address
    }

    #[view]
    public fun amnis(): String {
        utf8(b"Amnis")
    }

    #[view]
    public fun apt(): String {
        utf8(b"APT")
    }

    #[view]
    public fun usdc(): String {
        utf8(b"USDC")
    }

    #[view]
    public fun btc(): String {
        utf8(b"BTC")
    }

    #[view]
    public fun get_total_staked(
        token: String,
        protocol: String,
        token_out: String        
    ): u64 acquires LiquidVaultRef {
        let vault_ref = borrow_global<LiquidVaultRef>(HEDOS);
        if (protocol == amnis() && token == apt()) {
            let amount_stAPT = get_stAPT_balance(vault_ref.vault_address);

            let amount_balance_amAPT = get_amAPT_balance(vault_ref.vault_address);
            let amount_amAPT = ( (price_stAPT() as u128) * (amount_stAPT as u128) / (PRECISION as u128) ) as u64;
            let amount_amAPT_all = amount_amAPT + amount_balance_amAPT;
            let amount_usdc = get_X_to_Y_out(amount_amAPT_all, AMAPT_CHOOSEN, USDC_CHOOSEN);

            if (token_out == usdc()) {
                amount_usdc
            } else if (token_out == apt()) {
                amount_amAPT_all
            } else {
                abort 1;
                0
            }
        } else {
            abort 1;
            0
        }
    }

    #[view]
    public fun get_total_staked_slow(
        token: String,
        protocol: String,
        token_out: String        
    ): u64 acquires LiquidVaultRef {
        let vault_ref = borrow_global<LiquidVaultRef>(HEDOS);
        if (protocol == amnis() && token == apt()) {
            let amount_stAPT = get_stAPT_balance(vault_ref.vault_address);

            let amount_balance_amAPT = get_amAPT_balance(vault_ref.vault_address);
            let amount_amAPT = ( (price_stAPT() as u128) * (amount_stAPT as u128) / (PRECISION as u128) ) as u64;
            let amount_amAPT_all = amount_amAPT + amount_balance_amAPT;
            let amount_usdc = get_X_to_Y_out(amount_amAPT_all, APT_CHOOSEN, USDC_CHOOSEN);

            if (token_out == usdc()) {
                amount_usdc
            } else if (token_out == apt()) {
                amount_amAPT_all
            } else {
                abort 1;
                0
            }
        } else {
            abort 1;
            0
        }
    }

    public entry fun init_vault(signer: &signer) acquires LiquidVaultRef {
        only_admin(signer);
        let constructor_ref = &object::create_object(HEDOS);
        let vault_signer = &object::generate_signer(constructor_ref);
        let extend_ref = object::generate_extend_ref(constructor_ref);
        let new_vault_address = signer::address_of(vault_signer);

        let new_vault = LiquidVault {
        };
        move_to(vault_signer, new_vault);  

        if (!exists<LiquidVaultRef>(HEDOS)) {
            move_to(signer, LiquidVaultRef {
                vault_address: new_vault_address,
                vault_extend_ref: extend_ref,
            })
        } else {
            let vault_ref = borrow_global_mut<LiquidVaultRef>(HEDOS);
            vault_ref.vault_address = new_vault_address;
            vault_ref.vault_extend_ref = extend_ref;
        };

        emit(CreateNewVault {
            new_vault_address: new_vault_address
        });
    }

    public entry fun liquid_staking(
        signer: &signer, 
        amountUSDC: u64,
        token: String, 
        protocol: String
    ) acquires LiquidVaultRef {
        only_admin(signer);
        let vault_ref = borrow_global<LiquidVaultRef>(HEDOS);
        let vault_signer = &object::generate_signer_for_extending(&vault_ref.vault_extend_ref);
        let vault_address = vault_ref.vault_address;
        
        if (protocol == amnis() && token == apt()) {
            let amount_stake_before = get_apt_balance(vault_address);
            send_to_staking_vault(signer, amountUSDC);
            hyperion_swap_X_To_Y(vault_signer, amountUSDC, USDC_CHOOSEN, APT_CHOOSEN);
            let amount_stake_after = get_apt_balance(vault_address) ;
            let amount_stake = amount_stake_after - amount_stake_before;

            stake(vault_signer, amount_stake, vault_address);
        } else {
            abort 1;
        };
    }

    public entry fun liquid_staking_unstake(
        signer: &signer, 
        amountUSDC: u64,
        token: String, 
        protocol: String
    ) acquires LiquidVaultRef {
        only_admin(signer);
        let vault_ref = borrow_global<LiquidVaultRef>(HEDOS);
        let vault_signer = &object::generate_signer_for_extending(&vault_ref.vault_extend_ref);
        let vault_address = vault_ref.vault_address;
        
        if (protocol == amnis() && token == apt()) {
            let amApt_unstake = get_amount_in(amountUSDC, AMAPT_CHOOSEN, USDC_CHOOSEN);

            let st_unstake = (PRECISION * (amApt_unstake as u128) / (price_stAPT() as u128) ) as u64;

            let amAPT_balance_before = get_amAPT_balance(vault_address);
            unstake_amAPT(vault_signer, st_unstake, vault_address);
            let amAPT_balance_after = get_amAPT_balance(vault_address);

            hyperion_swap_X_To_Y(vault_signer, amAPT_balance_after - amAPT_balance_before, AMAPT_CHOOSEN, USDC_CHOOSEN);
        } else {
            abort 1;
        };

        transfer_usdc(vault_signer, get_vault_address(), amountUSDC);
    }

    public entry fun liquid_staking_unstake_all(
        signer: &signer,
        token: String, 
        protocol: String
    ) acquires LiquidVaultRef {
        only_admin(signer);
        let vault_ref = borrow_global<LiquidVaultRef>(HEDOS);
        let vault_signer = &object::generate_signer_for_extending(&vault_ref.vault_extend_ref);
        let vault_address = vault_ref.vault_address;

        if (protocol == amnis() && token == apt()) {
            let stAPT_balance = get_stAPT_balance(vault_address);
            unstake_amAPT(vault_signer, stAPT_balance, vault_address);
            
            let amAPT_balance = get_amAPT_balance(vault_address);
            hyperion_swap_X_To_Y(vault_signer, amAPT_balance, AMAPT_CHOOSEN, USDC_CHOOSEN);
        } else {
            abort 1;
        };

        transfer_usdc(vault_signer, get_vault_address(), get_usdc_balance(vault_address));
    }
}
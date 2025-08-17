module hedos::lending_actions {
    use hedos::interact_aries::{get_price, register_user, deposit, deposit_fa, withdraw, withdraw_fa, repay, total_loaning, total_lending, get_borrow_amount};
    use hedos::interact_hyperion::{hyperion_swap_X_To_Y, get_amount_in};
    use hedos::token::{get_apt_balance, get_usdc_balance, transfer_usdc};
    use hedos::white_list::{only_admin};
    use hedos::general_vault::{get_vault_address, send_to_lending_vault};

    use aptos_framework::object::{Self, ExtendRef};
    use aptos_framework::event::{emit};

    use std::signer;
    use std::string::{String, utf8};

    use wrapped_coins::wrapped_coins::WrappedUSDC;
    use aptos_framework::aptos_coin::AptosCoin;

    const HEDOS: address = @hedos;

    const USDC_CHOOSEN: u8 = 1;
    const APT_CHOOSEN: u8 = 2;
    const AMAPT_CHOOSEN: u8 = 3;
    #[event]
    struct CreateNewVault has drop, store {
        new_vault_address: address
    }

    struct LendingVault has key {
    }

    struct LendingVaultRef has key {
        vault_address: address,
        vault_extend_ref: ExtendRef,
    }

    #[view]
    public fun get_lending_vault_address(): address acquires LendingVaultRef {
        let vault_ref = borrow_global<LendingVaultRef>(HEDOS);
        vault_ref.vault_address
    }

    #[view]
    public fun get_total_lending(
        token: String, 
        protocol: String
    ): u64 acquires LendingVaultRef  {
        let vault_address = get_lending_vault_address();
        
        if (protocol == aries()) {
            if (token == usdc()) {
                total_lending<WrappedUSDC>(vault_address)
            } else if (token == apt()) {
                total_lending<AptosCoin>(vault_address)
            } else {
                abort 1
            }
        } else {
            abort 1
        }
    }

    #[view]
    public fun get_total_loaning(
        token: String, 
        protocol: String
    ): u64 acquires LendingVaultRef  {
        let vault_address = get_lending_vault_address();

        if (protocol == aries()) {
            if (token == apt()) {
                total_loaning<AptosCoin>(vault_address) as u64
            } else {
                abort 1
            }
        } else {
            abort 1
        }
    }

    #[view]
    public fun get_lending_price(
        token: String, 
        protocol: String
    ): u64 {
        if (protocol == aries()) {
            if (token == usdc()) {
                (get_price<WrappedUSDC>() / 10000) as u64
            } else if (token == apt()) {
                (get_price<AptosCoin>() / 100) as u64
            } else {
                abort 1
            }
        } else {
            abort 1
        }
    }

    #[view]
    public fun aries(): String {
        utf8(b"Aries")
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

    public entry fun init_vault(signer: &signer) acquires LendingVaultRef {
        only_admin(signer);
        let constructor_ref = &object::create_object(HEDOS);
        let vault_signer = &object::generate_signer(constructor_ref);
        let extend_ref = object::generate_extend_ref(constructor_ref);
        let new_vault_address = signer::address_of(vault_signer);
        register_user(vault_signer);

        let new_vault = LendingVault {
        };
        move_to(vault_signer, new_vault);  

        if (!exists<LendingVaultRef>(HEDOS)) {
            move_to(signer, LendingVaultRef {
                vault_address: new_vault_address,
                vault_extend_ref: extend_ref,
            })
        } else {
            let vault_ref = borrow_global_mut<LendingVaultRef>(HEDOS);
            vault_ref.vault_address = new_vault_address;
            vault_ref.vault_extend_ref = extend_ref;
        };
        

        emit(CreateNewVault {
            new_vault_address: new_vault_address
        });
    }

    public entry fun lending_deposit(
        signer: &signer, 
        amount: u64, 
        token: String, 
        protocol: String
    ) acquires LendingVaultRef {
        only_admin(signer);
        let vault_ref = borrow_global<LendingVaultRef>(HEDOS);
        let vault_signer = &object::generate_signer_for_extending(&vault_ref.vault_extend_ref);
        let vault_address = vault_ref.vault_address;
        let usdc_balance = get_usdc_balance(vault_address);
        
        if (protocol == aries()) {
            if (token == usdc()) {
                if (amount > usdc_balance) {
                    send_to_lending_vault(signer, amount - usdc_balance);
                };
                deposit_fa<WrappedUSDC>(vault_signer, amount);
            } else if (token == apt()) {
                let apt_need = amount - get_apt_balance(vault_address);

                if (apt_need > 0) {
                    let amount_in = get_amount_in(apt_need, USDC_CHOOSEN, APT_CHOOSEN);
                    if (amount_in > usdc_balance) {
                        send_to_lending_vault(signer, amount_in - usdc_balance);
                    };
                    hyperion_swap_X_To_Y(vault_signer, amount_in, USDC_CHOOSEN, APT_CHOOSEN);
                };

                deposit<AptosCoin>(vault_signer, amount, false);
            } else {
                abort 1;
            };
        } else {
            abort 1;
        };
    }

    public entry fun lending_borrow(
        signer: &signer, 
        amount: u64, 
        token: String, 
        protocol: String
    ) acquires LendingVaultRef {
        only_admin(signer);
        let vault_ref = borrow_global<LendingVaultRef>(HEDOS);
        let vault_signer = &object::generate_signer_for_extending(&vault_ref.vault_extend_ref);
        let vault_address = vault_ref.vault_address;

        if (protocol == aries()) {
            if (token == apt()) {
                withdraw<AptosCoin>(vault_signer, amount, true);
                hyperion_swap_X_To_Y(vault_signer, get_apt_balance(vault_address), APT_CHOOSEN, USDC_CHOOSEN);
            } else {
                abort 1;
            };
        } else {
            abort 1;
        };
        transfer_usdc(vault_signer, get_vault_address(), get_usdc_balance(vault_address));
    }

    public entry fun lending_deposit_and_borrow(
        signer: &signer, 
        amount_deposit: u64, 
        token_deposit: String,
        amount_borrow: u64,
        token_borrow: String,
        protocol: String
    ) acquires LendingVaultRef {
        only_admin(signer);
        lending_deposit(signer, amount_deposit, token_deposit, protocol);
        lending_borrow(signer, amount_borrow, token_borrow, protocol);
    }

    public entry fun lending_deposit_and_borrow_by_rate(
        signer: &signer, 
        amount_deposit: u64, 
        token_deposit: String,
        token_borrow: String,
        protocol: String,
        rate: u64
    ) acquires LendingVaultRef {
        only_admin(signer);

        if (protocol == aries() && token_deposit == usdc() && token_borrow == apt()) {
            let (_, amount_borrow) = get_borrow_amount<WrappedUSDC, AptosCoin>(amount_deposit, rate);
            lending_deposit(signer, amount_deposit, token_deposit, protocol);
            lending_borrow(signer, amount_borrow, token_borrow, protocol);
        } else {
            abort 1;
        };
    }
    
    public entry fun lending_repay(
        signer: &signer, 
        amount: u64, 
        token: String, 
        protocol: String
    ) acquires LendingVaultRef {
        only_admin(signer);
        let vault_ref = borrow_global<LendingVaultRef>(HEDOS);
        let vault_signer = &object::generate_signer_for_extending(&vault_ref.vault_extend_ref);
        let vault_address = vault_ref.vault_address;
        let usdc_balance = get_usdc_balance(vault_address);

        if (protocol == aries() && token == apt()) {
            let apt_need = amount - get_apt_balance(vault_address);

            if (apt_need > 0) {
                let amount_in = get_amount_in(apt_need, USDC_CHOOSEN, APT_CHOOSEN);
                if (amount_in > usdc_balance) {
                    send_to_lending_vault(signer, amount_in - usdc_balance);
                };
                hyperion_swap_X_To_Y(vault_signer, amount_in, USDC_CHOOSEN, APT_CHOOSEN);
            };
            
            repay<AptosCoin>(vault_signer, amount);
        } else {
            abort 1;
        };
    }

    public entry fun lending_withdraw(
        signer: &signer, 
        amount: u64, 
        token: String, 
        protocol: String
    ) acquires LendingVaultRef {
        only_admin(signer);
        let vault_ref = borrow_global<LendingVaultRef>(HEDOS);
        let vault_signer = &object::generate_signer_for_extending(&vault_ref.vault_extend_ref);
        let vault_address = vault_ref.vault_address;
        
        if (token == usdc() && protocol == aries()) {
            withdraw_fa<WrappedUSDC>(vault_signer, amount, false);
        } else if (token == apt() && protocol == aries()) {
            withdraw<AptosCoin>(vault_signer, amount, false);
            hyperion_swap_X_To_Y(vault_signer, get_apt_balance(vault_address), APT_CHOOSEN, USDC_CHOOSEN);
        } else {
            abort 1;
        };
        transfer_usdc(vault_signer, get_vault_address(), get_usdc_balance(vault_address));
    }

    public entry fun lending_repay_and_withdraw(
        signer: &signer, 
        amount_repay: u64, 
        token_repay: String,  
        amount_withdraw: u64, 
        token_withdraw: String, 
        protocol: String
    ) acquires LendingVaultRef {
        only_admin(signer);
    
        if (protocol == aries() && token_repay == apt() && token_withdraw == usdc()) {
            lending_repay(signer, amount_repay, token_repay, protocol);
            lending_withdraw(signer, amount_withdraw, token_withdraw, protocol);
        } else {
            abort 1;
        };
    }

    public entry fun lending_repay_all(
        signer: &signer, 
        token: String, 
        protocol: String
    ) acquires LendingVaultRef {
        only_admin(signer);

        let amount_repay = get_total_loaning(token, protocol) + 1;
        
        lending_repay(signer, amount_repay, token, protocol);
    }

    public entry fun lending_withdraw_all(
        signer: &signer, 
        token: String, 
        protocol: String
    ) acquires LendingVaultRef {
        only_admin(signer);

        let amount_withdraw = get_total_lending(token, protocol);
    
        lending_withdraw(signer, amount_withdraw, token, protocol);
    }
}
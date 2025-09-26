module hedos::lending_actions {
    use hedos::interact_aries::{
        get_price,
        register_user,
        deposit,
        deposit_fa,
        withdraw,
        withdraw_fa,
        repay,
        total_loaning,
        total_lending,
        get_borrow_amount
    };
    use hedos::interact_hyperion::{hyperion_swap_X_To_Y, get_amount_in};
    use hedos::token::{get_balance, get_usdc_balance, transfer_usdc};
    use hedos::white_list::{only_admin};
    use hedos::general_vault::{get_vault_address, send_to_lending_vault};

    use aptos_framework::object::{Self, ExtendRef};
    use aptos_framework::event::{emit};

    use std::signer;
    use std::string::{String, utf8};

    use wrapped_coins::wrapped_coins::WrappedUSDC;
    use wrapped_coins::wrapped_coins::WrappedXBTC;
    use wrapped_coins::wrapped_coins::WrappedWBTC;
    use aptos_framework::aptos_coin::AptosCoin;

    const HEDOS: address = @hedos;

    const USDC_CHOOSEN: u8 = 1;
    const APT_CHOOSEN: u8 = 2;
    const AMAPT_CHOOSEN: u8 = 3;
    const XBTC_CHOOSEN: u8 = 4;
    const WBTC_CHOOSEN: u8 = 5;

    #[event]
    struct CreateNewVault has drop, store {
        new_vault_address: address
    }

    struct LendingVault has key {}

    struct LendingVaultRef has key {
        vault_address: address,
        vault_extend_ref: ExtendRef
    }

    struct TokenVault has key {}

    struct TokenVaultRef has key {
        vault_address: address,
        vault_extend_ref: ExtendRef
    }

    #[view]
    public fun get_lending_vault_address(): address acquires LendingVaultRef {
        let vault_ref = borrow_global<LendingVaultRef>(HEDOS);
        vault_ref.vault_address
    }

    #[view]
    public fun get_token_vault_address(): address acquires TokenVaultRef {
        let vault_ref = borrow_global<TokenVaultRef>(HEDOS);
        vault_ref.vault_address
    }

    #[view]
    public fun get_total_lending(
        token: String, protocol: String
    ): u64 acquires LendingVaultRef, TokenVaultRef {
        let vault_address = get_lending_vault_address();
        if (token != usdc()) {
            vault_address = get_token_vault_address();
        };

        if (protocol == aries()) {
            if (token == usdc()) {
                total_lending<WrappedUSDC>(vault_address)
            } else if (token == apt()) {
                total_lending<AptosCoin>(vault_address)
            } else if (token == xbtc()) {
                total_lending<WrappedXBTC>(vault_address)
            } else if (token == wbtc()) {
                total_lending<WrappedWBTC>(vault_address)
            } else {
                abort 1
            }
        } else {
            abort 1
        }
    }

    #[view]
    public fun get_total_loaning(token: String, protocol: String): u64 acquires LendingVaultRef {
        let vault_address = get_lending_vault_address();

        if (protocol == aries()) {
            if (token == apt()) {
                total_loaning<AptosCoin>(vault_address) as u64
            } else if (token == xbtc()) {
                total_loaning<WrappedXBTC>(vault_address) as u64
            } else if (token == wbtc()) {
                total_loaning<WrappedWBTC>(vault_address) as u64
            } else {
                abort 1
            }
        } else {
            abort 1
        }
    }

    #[view]
    public fun get_lending_price(token: String, protocol: String): u64 {
        if (protocol == aries()) {
            if (token == usdc()) {
                (get_price<WrappedUSDC>() / 10000) as u64
            } else if (token == apt()) {
                (get_price<AptosCoin>() / 100) as u64
            } else if (token == xbtc()) {
                (get_price<WrappedXBTC>() * 10) as u64
            } else if (token == wbtc()) {
                (get_price<WrappedWBTC>() * 10) as u64
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

    #[view]
    public fun xbtc(): String {
        utf8(b"XBTC")
    }

    #[view]
    public fun wbtc(): String {
        utf8(b"WBTC")
    }

    fun id_token(token: String): u8 {
        if (token == usdc()) {
            USDC_CHOOSEN
        } else if (token == apt()) {
            APT_CHOOSEN
        } else if (token == xbtc()) {
            XBTC_CHOOSEN
        } else if (token == wbtc()) {
            WBTC_CHOOSEN
        } else {
            abort 1
        }
    }

    public entry fun init_token_vault(signer: &signer) {
        only_admin(signer);
        let constructor_ref = &object::create_object(HEDOS);
        let vault_signer = &object::generate_signer(constructor_ref);
        let extend_ref = object::generate_extend_ref(constructor_ref);
        let new_vault_address = signer::address_of(vault_signer);
        register_user(vault_signer);

        let new_vault = TokenVault {};
        move_to(vault_signer, new_vault);

        if (!exists<TokenVaultRef>(HEDOS)) {
            move_to(
                signer,
                TokenVaultRef {
                    vault_address: new_vault_address,
                    vault_extend_ref: extend_ref
                }
            )
        };

        emit(CreateNewVault { new_vault_address: new_vault_address });
    }

    public entry fun init_vault(signer: &signer) {
        only_admin(signer);
        let constructor_ref = &object::create_object(HEDOS);
        let vault_signer = &object::generate_signer(constructor_ref);
        let extend_ref = object::generate_extend_ref(constructor_ref);
        let new_vault_address = signer::address_of(vault_signer);
        register_user(vault_signer);

        let new_vault = LendingVault {};
        move_to(vault_signer, new_vault);

        if (!exists<LendingVaultRef>(HEDOS)) {
            move_to(
                signer,
                LendingVaultRef {
                    vault_address: new_vault_address,
                    vault_extend_ref: extend_ref
                }
            )
        };

        init_token_vault(signer);

        emit(CreateNewVault { new_vault_address: new_vault_address });
    }

    public entry fun lending_deposit(
        signer: &signer,
        amount: u64,
        token: String,
        protocol: String
    ) acquires LendingVaultRef, TokenVaultRef {
        only_admin(signer);
        let vault_ref = borrow_global<LendingVaultRef>(HEDOS);
        let vault_signer =
            &object::generate_signer_for_extending(&vault_ref.vault_extend_ref);
        let vault_address = vault_ref.vault_address;

        let token_vault_ref = borrow_global<TokenVaultRef>(HEDOS);
        let token_vault_signer =
            &object::generate_signer_for_extending(&token_vault_ref.vault_extend_ref);
        let token_vault_address = token_vault_ref.vault_address;

        let usdc_balance = get_usdc_balance(vault_address);

        if (protocol == aries()) {
            if (token == usdc()) {
                if (amount > usdc_balance) {
                    send_to_lending_vault(signer, amount - usdc_balance);
                };
                deposit_fa<WrappedUSDC>(vault_signer, amount);
            } else if (token == apt() || token == xbtc() || token == wbtc()) {
                let amount_need = amount - get_balance(token_vault_address, token);
                let token_choosen = id_token(token);

                if (amount_need > 0) {
                    let amount_in = get_amount_in(
                        amount_need, USDC_CHOOSEN, token_choosen
                    );
                    if (amount_in > usdc_balance) {
                        send_to_lending_vault(signer, amount_in - usdc_balance);
                        transfer_usdc(
                            vault_signer, token_vault_address, amount_in - usdc_balance
                        );
                    };
                    hyperion_swap_X_To_Y(
                        token_vault_signer,
                        amount_in,
                        USDC_CHOOSEN,
                        token_choosen
                    );
                };

                if (token == apt()) {
                    deposit<AptosCoin>(token_vault_signer, amount, false);
                } else if (token == xbtc()) {
                    deposit_fa<WrappedXBTC>(token_vault_signer, amount);
                } else if (token == wbtc()) {
                    deposit_fa<WrappedWBTC>(token_vault_signer, amount);
                } else {
                    abort 1;
                };

                let token_balance = get_balance(token_vault_address, token);
                if (token_balance > 0) {
                    hyperion_swap_X_To_Y(
                        token_vault_signer,
                        token_balance,
                        token_choosen,
                        USDC_CHOOSEN
                    );
                    transfer_usdc(
                        token_vault_signer,
                        get_vault_address(),
                        get_usdc_balance(token_vault_address)
                    );
                };
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
        let vault_signer =
            &object::generate_signer_for_extending(&vault_ref.vault_extend_ref);
        let vault_address = vault_ref.vault_address;

        if (protocol == aries()) {
            let token_choosen = id_token(token);
            if (token == apt()) {
                withdraw<AptosCoin>(vault_signer, amount, true);
                // } else if (token == xbtc()) {
                //     withdraw_fa<WrappedXBTC>(vault_signer, amount, true);
            } else if (token == wbtc()) {
                withdraw_fa<WrappedWBTC>(vault_signer, amount, true);
            } else {
                abort 1;
            };
            hyperion_swap_X_To_Y(
                vault_signer,
                get_balance(vault_address, token),
                token_choosen,
                USDC_CHOOSEN
            );
        } else {
            abort 1;
        };
        transfer_usdc(
            vault_signer, get_vault_address(), get_usdc_balance(vault_address)
        );
    }

    public entry fun lending_deposit_and_borrow(
        signer: &signer,
        amount_deposit: u64,
        token_deposit: String,
        amount_borrow: u64,
        token_borrow: String,
        protocol: String
    ) acquires LendingVaultRef, TokenVaultRef {
        only_admin(signer);
        lending_deposit(
            signer,
            amount_deposit,
            token_deposit,
            protocol
        );
        lending_borrow(signer, amount_borrow, token_borrow, protocol);
    }

    public entry fun lending_deposit_and_borrow_by_rate(
        signer: &signer,
        amount_deposit: u64,
        token_deposit: String,
        token_borrow: String,
        protocol: String,
        rate: u64
    ) acquires LendingVaultRef, TokenVaultRef {
        only_admin(signer);

        if (protocol == aries() && token_deposit == usdc()) {
            let amount_borrow;

            if (token_borrow == apt()) {
                (_, amount_borrow) = get_borrow_amount<WrappedUSDC, AptosCoin>(
                    amount_deposit, rate
                );
            } else if (token_borrow == wbtc()) {
                (_, amount_borrow) = get_borrow_amount<WrappedUSDC, WrappedWBTC>(
                    amount_deposit, rate
                );
            } else {
                abort 1;
            };

            lending_deposit(
                signer,
                amount_deposit,
                token_deposit,
                protocol
            );
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
        let vault_signer =
            &object::generate_signer_for_extending(&vault_ref.vault_extend_ref);
        let vault_address = vault_ref.vault_address;
        let usdc_balance = get_usdc_balance(vault_address);

        if (protocol == aries()) {
            let amount_need = amount - get_balance(vault_address, token);
            let token_choosen = id_token(token);

            if (amount_need > 0) {
                let amount_in = get_amount_in(amount_need, USDC_CHOOSEN, token_choosen);
                if (amount_in > usdc_balance) {
                    send_to_lending_vault(signer, amount_in - usdc_balance);
                };
                hyperion_swap_X_To_Y(
                    vault_signer,
                    amount_in,
                    USDC_CHOOSEN,
                    token_choosen
                );
            };
            if (token == apt()) {
                repay<AptosCoin>(vault_signer, amount);
                // } else if (token == xbtc()) {
                //     deposit_fa<WrappedXBTC>(vault_signer, amount);
            } else if (token == wbtc()) {
                deposit_fa<WrappedWBTC>(vault_signer, amount);
            } else {
                abort 1;
            };

            let token_balance = get_balance(vault_address, token);
            if (token_balance > 0) {
                hyperion_swap_X_To_Y(
                    vault_signer,
                    token_balance,
                    token_choosen,
                    USDC_CHOOSEN
                );
                transfer_usdc(
                    vault_signer, get_vault_address(), get_usdc_balance(vault_address)
                );
            };
        } else {
            abort 1;
        };
    }

    public entry fun lending_withdraw(
        signer: &signer,
        amount: u64,
        token: String,
        protocol: String
    ) acquires LendingVaultRef, TokenVaultRef {
        only_admin(signer);
        let vault_ref = borrow_global<LendingVaultRef>(HEDOS);
        let vault_signer =
            &object::generate_signer_for_extending(&vault_ref.vault_extend_ref);
        let vault_address = vault_ref.vault_address;

        let token_vault_ref = borrow_global<TokenVaultRef>(HEDOS);
        let token_vault_signer =
            &object::generate_signer_for_extending(&token_vault_ref.vault_extend_ref);
        let token_vault_address = token_vault_ref.vault_address;

        if (protocol == aries()) {
            if (token == usdc()) {
                withdraw_fa<WrappedUSDC>(vault_signer, amount, false);
            } else {
                if (token == apt()) {
                    withdraw<AptosCoin>(token_vault_signer, amount, false);
                } else if (token == xbtc()) {
                    withdraw_fa<WrappedXBTC>(token_vault_signer, amount, false);
                } else if (token == wbtc()) {
                    withdraw_fa<WrappedWBTC>(token_vault_signer, amount, false);
                } else {
                    abort 1;
                };

                if (amount > get_balance(token_vault_address, token)) {
                    amount = get_balance(token_vault_address, token);
                };
                hyperion_swap_X_To_Y(
                    token_vault_signer,
                    amount,
                    id_token(token),
                    USDC_CHOOSEN
                );
            };
        } else {
            abort 1;
        };
        transfer_usdc(
            token_vault_signer,
            get_vault_address(),
            get_usdc_balance(token_vault_address)
        );
        transfer_usdc(
            vault_signer, get_vault_address(), get_usdc_balance(vault_address)
        );
    }

    public entry fun lending_repay_and_withdraw(
        signer: &signer,
        amount_repay: u64,
        token_repay: String,
        amount_withdraw: u64,
        token_withdraw: String,
        protocol: String
    ) acquires LendingVaultRef, TokenVaultRef {
        only_admin(signer);

        if (protocol == aries()
            && (token_repay == apt()
                || token_repay == wbtc())
            && token_withdraw == usdc()) {
            lending_repay(signer, amount_repay, token_repay, protocol);
            lending_withdraw(
                signer,
                amount_withdraw,
                token_withdraw,
                protocol
            );
        } else {
            abort 1;
        };
    }

    public entry fun lending_repay_all(
        signer: &signer, token: String, protocol: String
    ) acquires LendingVaultRef {
        only_admin(signer);

        let amount_repay = get_total_loaning(token, protocol);

        lending_repay(signer, amount_repay, token, protocol);
    }

    public entry fun lending_withdraw_all(
        signer: &signer, token: String, protocol: String
    ) acquires LendingVaultRef, TokenVaultRef {
        only_admin(signer);

        let amount_withdraw = get_total_lending(token, protocol);

        lending_withdraw(signer, amount_withdraw, token, protocol);
    }

    public entry fun lending_repay_and_withdraw_all(
        signer: &signer,
        token_repay: String,
        token_withdraw: String,
        protocol: String
    ) acquires LendingVaultRef, TokenVaultRef {
        lending_repay_all(signer, token_repay, protocol);
        lending_withdraw_all(signer, token_withdraw, protocol);
    }

    public entry fun transfer_all_usdc_back(signer: &signer) acquires LendingVaultRef, TokenVaultRef {
        only_admin(signer);
        let vault_ref = borrow_global<LendingVaultRef>(HEDOS);
        let vault_signer =
            &object::generate_signer_for_extending(&vault_ref.vault_extend_ref);
        let vault_address = vault_ref.vault_address;

        let token_vault_ref = borrow_global<TokenVaultRef>(HEDOS);
        let token_vault_signer =
            &object::generate_signer_for_extending(&token_vault_ref.vault_extend_ref);
        let token_vault_address = token_vault_ref.vault_address;

        if (get_usdc_balance(vault_address) > 0) {
            transfer_usdc(
                vault_signer, get_vault_address(), get_usdc_balance(vault_address)
            );
        };

        if (get_usdc_balance(token_vault_address) > 0) {
            transfer_usdc(
                token_vault_signer,
                get_vault_address(),
                get_usdc_balance(token_vault_address)
            );
        };
    }
}


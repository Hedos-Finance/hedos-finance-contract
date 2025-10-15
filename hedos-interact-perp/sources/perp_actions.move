module hedos::perp_actions {
    use aptos_framework::object::{Self, ExtendRef};
    use aptos_framework::event::{emit};

    use hedos::general_vault::{get_vault_address, send_to_perp_vault};
    use hedos::token::{transfer_usdc, get_usdc_balance};
    use hedos::white_list::{only_admin, only_owner};
    use hedos::interact_merkle_trade::{simple_trade_by_leverage, simple_trade_by_size};

    use std::signer;
    use std::string::{String, utf8};

    const HEDOS: address = @hedos;

    #[view]
    public fun merkle(): String {
        utf8(b"Merkle")
    }

    #[view]
    public fun apt_usd(): String {
        utf8(b"APT_USD")
    }

    #[event]
    struct CreateNewVault has drop, store {
        new_vault_address: address
    }

    struct ShortVault has key {}

    struct LongVault has key {}

    struct PerpVaultRef has key {
        short_address: address,
        short_extend_ref: ExtendRef,
        long_address: address,
        long_extend_ref: ExtendRef
    }

    #[view]
    public fun get_perp_vault_address(): (address, address) acquires PerpVaultRef {
        let vault_ref = borrow_global<PerpVaultRef>(HEDOS);
        (vault_ref.short_address, vault_ref.long_address)
    }

    public entry fun init_vault(signer: &signer) {
        only_owner(signer);

        let short_constructor_ref = &object::create_object(HEDOS);
        let short_signer = &object::generate_signer(short_constructor_ref);
        let new_short_extend_ref = object::generate_extend_ref(short_constructor_ref);
        let new_short_address = signer::address_of(short_signer);
        let new_short = ShortVault {};
        move_to(short_signer, new_short);

        let long_constructor_ref = &object::create_object(HEDOS);
        let long_signer = &object::generate_signer(long_constructor_ref);
        let new_long_extend_ref = object::generate_extend_ref(long_constructor_ref);
        let new_long_address = signer::address_of(long_signer);
        let new_long = LongVault {};
        move_to(long_signer, new_long);

        if (!exists<PerpVaultRef>(HEDOS)) {
            move_to(
                signer,
                PerpVaultRef {
                    short_address: new_short_address,
                    short_extend_ref: new_short_extend_ref,
                    long_address: new_long_address,
                    long_extend_ref: new_long_extend_ref
                }
            )
        };

        emit(CreateNewVault { new_vault_address: new_short_address });

        emit(CreateNewVault { new_vault_address: new_long_address });
    }

    public entry fun transfer_all_usdc_back(signer: &signer) acquires PerpVaultRef {
        only_admin(signer);
        let vault_ref = borrow_global<PerpVaultRef>(HEDOS);

        let short_address = vault_ref.short_address;
        let long_address = vault_ref.long_address;

        let short_signer =
            &object::generate_signer_for_extending(&vault_ref.short_extend_ref);
        let long_signer =
            &object::generate_signer_for_extending(&vault_ref.long_extend_ref);

        if (get_usdc_balance(short_address) > 0) {
            transfer_usdc(
                short_signer, get_vault_address(), get_usdc_balance(short_address)
            );

        };
        if (get_usdc_balance(long_address) > 0) {
            transfer_usdc(
                long_signer, get_vault_address(), get_usdc_balance(long_address)
            );
        };
    }

    public entry fun perp_open_position(
        signer: &signer,
        collateral_delta: u64,
        leverage: u64,
        is_long: bool,
        market_skew: bool,
        pair: String,
        protocol: String
    ) acquires PerpVaultRef {
        only_admin(signer);
        let vault_ref = borrow_global<PerpVaultRef>(HEDOS);

        let short_address = vault_ref.short_address;
        let long_address = vault_ref.long_address;

        let short_signer =
            &object::generate_signer_for_extending(&vault_ref.short_extend_ref);
        let long_signer =
            &object::generate_signer_for_extending(&vault_ref.long_extend_ref);

        send_to_perp_vault(signer, collateral_delta);

        if (protocol == merkle()) {
            if (!is_long) {
                simple_trade_by_leverage(
                    short_signer,
                    short_address,
                    collateral_delta,
                    leverage,
                    is_long,
                    true,
                    market_skew,
                    pair
                );
            } else {
                transfer_usdc(short_signer, long_address, collateral_delta);
                simple_trade_by_leverage(
                    long_signer,
                    long_address,
                    collateral_delta,
                    leverage,
                    is_long,
                    true,
                    market_skew,
                    pair
                );
            };
        } else {
            abort 1;
        };
    }

    public entry fun perp_close_position(
        signer: &signer,
        collateral_delta: u64,
        leverage: u64,
        is_long: bool,
        market_skew: bool,
        pair: String,
        protocol: String
    ) acquires PerpVaultRef {
        only_admin(signer);
        let vault_ref = borrow_global<PerpVaultRef>(HEDOS);

        let short_address = vault_ref.short_address;
        let long_address = vault_ref.long_address;

        let short_signer =
            &object::generate_signer_for_extending(&vault_ref.short_extend_ref);
        let long_signer =
            &object::generate_signer_for_extending(&vault_ref.long_extend_ref);

        if (protocol == merkle()) {
            if (!is_long) {
                simple_trade_by_leverage(
                    short_signer,
                    short_address,
                    collateral_delta,
                    leverage,
                    is_long,
                    false,
                    market_skew,
                    pair
                );
            } else {
                simple_trade_by_leverage(
                    long_signer,
                    long_address,
                    collateral_delta,
                    leverage,
                    is_long,
                    false,
                    market_skew,
                    pair
                );
            };
        } else {
            abort 1;
        };
    }

    public entry fun perp_open_position_by_size(
        signer: &signer,
        collateral_delta: u64,
        size_delta: u64,
        is_long: bool,
        market_skew: bool,
        pair: String,
        protocol: String
    ) acquires PerpVaultRef {
        only_admin(signer);
        let vault_ref = borrow_global<PerpVaultRef>(HEDOS);

        let short_address = vault_ref.short_address;
        let long_address = vault_ref.long_address;

        let short_signer =
            &object::generate_signer_for_extending(&vault_ref.short_extend_ref);
        let long_signer =
            &object::generate_signer_for_extending(&vault_ref.long_extend_ref);

        send_to_perp_vault(signer, collateral_delta);

        if (protocol == merkle()) {
            if (!is_long) {
                simple_trade_by_size(
                    short_signer,
                    short_address,
                    collateral_delta,
                    size_delta,
                    is_long,
                    true,
                    market_skew,
                    pair
                );
            } else {
                transfer_usdc(short_signer, long_address, collateral_delta);
                simple_trade_by_size(
                    long_signer,
                    long_address,
                    collateral_delta,
                    size_delta,
                    is_long,
                    true,
                    market_skew,
                    pair
                );
            };
        } else {
            abort 1;
        };
    }

    public entry fun perp_close_position_by_size(
        signer: &signer,
        collateral_delta: u64,
        size_delta: u64,
        is_long: bool,
        market_skew: bool,
        pair: String,
        protocol: String
    ) acquires PerpVaultRef {
        only_admin(signer);
        let vault_ref = borrow_global<PerpVaultRef>(HEDOS);

        let short_address = vault_ref.short_address;
        let long_address = vault_ref.long_address;

        let short_signer =
            &object::generate_signer_for_extending(&vault_ref.short_extend_ref);
        let long_signer =
            &object::generate_signer_for_extending(&vault_ref.long_extend_ref);

        if (protocol == merkle()) {
            if (!is_long) {
                simple_trade_by_size(
                    short_signer,
                    short_address,
                    collateral_delta,
                    size_delta,
                    is_long,
                    false,
                    market_skew,
                    pair
                );
            } else {
                simple_trade_by_size(
                    long_signer,
                    long_address,
                    collateral_delta,
                    size_delta,
                    is_long,
                    false,
                    market_skew,
                    pair
                );
            };
        } else {
            abort 1;
        };
    }
}


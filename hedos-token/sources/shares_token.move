module hedos::shares_token {
    use aptos_framework::object::{Self, Object, ExtendRef};
    use aptos_framework::aptos_account::{transfer_fungible_assets};
    use aptos_framework::fungible_asset::{Self, MintRef, TransferRef, BurnRef, MutateMetadataRef, Metadata };
    use aptos_framework::primary_fungible_store;
    use std::signer;
    use std::option::{Self, Option};
    use std::event;
    use std::string::{bytes, utf8, String};
    use aptos_framework::event::emit;

    use hedos::white_list::{only_admin};

    const HEDOS: address = @hedos;

    struct SharesTokenRefs has key {
        extendRef: ExtendRef,
        mintRef: MintRef,
        burnRef: BurnRef,
        transferRef: TransferRef,

        mutateMetadataRef: MutateMetadataRef, 
    }

    struct SharesTokenAddress has key {
        safety_address: address,
        risky_address: address,
    }

    #[event]
    struct Mint has drop, store {
        minter: address,
        to: address,
        amount: u64,
    }

    #[event]
    struct Burn has drop, store {
        minter: address,
        from: address,
        amount: u64,
    }

    #[event]
    struct TokenCreated has drop, store {
        creator: address,
        token: address,
    }

    #[view]
    public fun metadata(tokenAddress: address): Object<Metadata> {
        object::address_to_object<Metadata>(tokenAddress)
    }

    #[view]
    public fun balance(tokenAddress: address, from: address): u64 {
        let fromStore = primary_fungible_store::ensure_primary_store_exists(from, metadata(tokenAddress));
        fungible_asset::balance(fromStore)
    }

    #[view]
    public fun get_total_safety_supply(): u128 acquires SharesTokenAddress {
        let (safety_address, _) = get_shares_token_address();
        let safety = object::address_to_object<Metadata>(safety_address);
        option::get_with_default(&fungible_asset::supply(safety), 0)
        
    }

    #[view]
    public fun get_total_risky_supply(): u128 acquires SharesTokenAddress {
        let (_, risky_address) = get_shares_token_address();
        let risky = object::address_to_object<Metadata>(risky_address);
        option::get_with_default(&fungible_asset::supply(risky), 0)
    } 

    #[view]
    public fun get_total_supply(): (u128, u128) acquires SharesTokenAddress {
        (get_total_safety_supply(), get_total_risky_supply())
    }

    #[view]
    public fun get_user_shares(
        from: address
    ): (u64, u64) acquires SharesTokenAddress {
        let (safety_address, risky_address) = get_shares_token_address();
        
        (
            balance(safety_address, from),
            balance(risky_address, from)
        )
    }

    #[view]
    public fun get_shares_token_address(): (address, address) acquires SharesTokenAddress {
        let add = borrow_global<SharesTokenAddress>(HEDOS);
        (add.safety_address, add.risky_address)
    }

    public entry fun create_token(
        admin: &signer,
        name: String,
        symbol: String,
        icon_uri: String,
        project_uri: String
    ) acquires SharesTokenAddress {
        only_admin(admin);
        let constructorRef = &object::create_named_object(admin, *bytes(&symbol));
        primary_fungible_store::create_primary_store_enabled_fungible_asset(
            constructorRef,
            option::none(),
            name,
            symbol,
            8,
            icon_uri,
            project_uri,
        );

        let metadata_object_signer = &object::generate_signer(constructorRef);
        move_to(metadata_object_signer, SharesTokenRefs {
            extendRef: object::generate_extend_ref(constructorRef),
            mintRef: fungible_asset::generate_mint_ref(constructorRef),
            burnRef: fungible_asset::generate_burn_ref(constructorRef),
            transferRef: fungible_asset::generate_transfer_ref(constructorRef),

            mutateMetadataRef: fungible_asset::generate_mutate_metadata_ref(constructorRef),
        });

        emit(TokenCreated {
            creator: signer::address_of(admin),
            token: object::address_from_constructor_ref(constructorRef)
        });

        let safety_address = HEDOS;
        let risky_address = HEDOS;

        if (name == utf8(b"Safety")) {
            safety_address = object::address_from_constructor_ref(constructorRef);
        } else if (name == utf8(b"Risky")) {
            risky_address = object::address_from_constructor_ref(constructorRef);
        } else {
            abort 1;
        };

        if (!exists<SharesTokenAddress>(HEDOS)) {
            move_to(admin, SharesTokenAddress {
                safety_address,
                risky_address,
            });
        } else {
            let add = borrow_global_mut<SharesTokenAddress>(HEDOS);
            if (safety_address != HEDOS) {
                add.safety_address = safety_address;
            } else if (risky_address != HEDOS) {
                add.risky_address = risky_address;
            } else {
                abort 1;
            };
        };
    }

    public entry fun set_address(
        admin: &signer,
        safety_address: address,
        risky_address: address
    ) acquires SharesTokenAddress {
        only_admin(admin);
        if (!exists<SharesTokenAddress>(HEDOS)) {
            move_to(admin, SharesTokenAddress {
                safety_address,
                risky_address,
            });
        } else {
            let add = borrow_global_mut<SharesTokenAddress>(HEDOS);
            add.safety_address = safety_address;
            add.risky_address = risky_address;
        };
    }

    public entry fun setting_safety_metadata(
        admin: &signer,
        name: Option<String>,
        symbol: Option<String>,
        decimals: Option<u8>,
        icon_uri: Option<String>,
        project_uri: Option<String>,
    ) acquires SharesTokenRefs, SharesTokenAddress {
        only_admin(admin);
        let (safety_address, _) = get_shares_token_address();
        fungible_asset::mutate_metadata(
            &borrow_global<SharesTokenRefs>(safety_address).mutateMetadataRef,
            name,
            symbol,
            decimals,
            icon_uri,
            project_uri
        );
    }

    public entry fun setting_risky_metadata(
        admin: &signer,
        name: Option<String>,
        symbol: Option<String>,
        decimals: Option<u8>,
        icon_uri: Option<String>,
        project_uri: Option<String>,
    ) acquires SharesTokenRefs, SharesTokenAddress {
        only_admin(admin);
        let (_, risky_address) = get_shares_token_address();
        fungible_asset::mutate_metadata(
            &borrow_global<SharesTokenRefs>(risky_address).mutateMetadataRef,
            name,
            symbol,
            decimals,
            icon_uri,
            project_uri
        );
    }

    public entry fun mint_safety(
        admin: &signer,
        to: address,
        amount: u64
    ) acquires SharesTokenRefs, SharesTokenAddress {
        let (safety_address, _) = get_shares_token_address();
        mint(admin, to, amount, safety_address);
    }

    public entry fun mint_risky(
        admin: &signer,
        to: address,
        amount: u64
    ) acquires SharesTokenRefs, SharesTokenAddress {
        let (_, risky_address) = get_shares_token_address();
        mint(admin, to, amount, risky_address);
    }

    fun mint(
        admin: &signer,
        to: address,
        amount: u64,
        tokenAddress: address
    ) acquires SharesTokenRefs {
        only_admin(admin);
        let tokenRefs = borrow_global<SharesTokenRefs>(tokenAddress);
        let assets = fungible_asset::mint(&tokenRefs.mintRef, amount);
        fungible_asset::deposit_with_ref(&tokenRefs.transferRef, primary_fungible_store::ensure_primary_store_exists(to, metadata(tokenAddress)), assets);

        event::emit(Mint {
            minter: signer::address_of(admin),
            to,
            amount,
        });
    }

    public entry fun burn_safety(
        admin: &signer,
        to: address,
        amount: u64
    ) acquires SharesTokenRefs, SharesTokenAddress {
        let (safety_address, _) = get_shares_token_address();
        burn(admin, to, amount, safety_address);
    }

    public entry fun burn_risky(
        admin: &signer,
        to: address,
        amount: u64
    ) acquires SharesTokenRefs, SharesTokenAddress {
        let (_, risky_address) = get_shares_token_address();
        burn(admin, to, amount, risky_address);
    }

    fun burn(
        admin: &signer,
        from: address,
        amount: u64,
        tokenAddress: address
    ) acquires SharesTokenRefs {
        only_admin(admin);
        let tokenRefs = borrow_global<SharesTokenRefs>(tokenAddress);
        let assets = fungible_asset::withdraw_with_ref(&tokenRefs.transferRef, primary_fungible_store::ensure_primary_store_exists(from, metadata(tokenAddress)), amount,);
        fungible_asset::burn(&tokenRefs.burnRef, assets);

        event::emit(Burn {
            minter: signer::address_of(admin),
            from,
            amount,
        });
    }

    public entry fun transfer_safety(
        from: &signer,
        to: address,
        amount: u64
    ) acquires SharesTokenAddress {
        let (safety_address, _) = get_shares_token_address();
        let safety = object::address_to_object<Metadata>(safety_address);
        transfer_fungible_assets(from, safety, to, amount);
    }

    public entry fun transfer_risky(
        from: &signer,
        to: address,
        amount: u64
    ) acquires SharesTokenAddress {
        let (_, risky_address) = get_shares_token_address();
        let risky = object::address_to_object<Metadata>(risky_address);
        transfer_fungible_assets(from, risky, to, amount);
    }
}
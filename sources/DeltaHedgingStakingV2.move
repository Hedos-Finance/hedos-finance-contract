module hello_aptos_network::DeltaHedgingStakingV2 {

    use hello_aptos_network::DeltaHedgingStakingV2Storage;

    use std::signer;

    use amnis::router;
    use amnis::delegation_manager;
    use amnis::amapt_token::AmnisApt;

    use aptos_framework::fungible_asset::Metadata;
    use aptos_framework::object::{Self};
    use aptos_framework::aptos_coin::AptosCoin;

    use dex_contract::router_v3;
    use dex_contract::pool_v3;

    const LS_V0: u8 = 0;
    const LS_V05: u8 = 5;

    const AMAPT_ADDRESS:    address = @fungible_AMAPT;
    const APT_ADDRESS:      address = @fungible_APT;
    const LZ_USDT_ADDRESS:  address = @fungible_lzUSDT;
    const USDT_ADDRESS:     address = @fungible_USDT;
    const USDC_ADDRESS:     address = @fungible_USDC;

    const APT_USDT_LP_ADR: address = @fungible_APT_USDT_LP;
    const USDT_USDC_LP_ADR: address = @fungible_USDT_USDC_LP;
    const AMAPT_APT_LP_ADR: address = @fungible_AMAPT_APT_LP;

    const USDC_CHOOSEN: u8 = 1;
    const APT_CHOOSEN: u8 = 2;
    const AMAPT_CHOOSEN: u8 = 3;
    
    public entry fun stake(
        owner_signer: &signer,
        user_address: address,
        amount: u64
    ) {
        assert!(amount > 0, 0);
        assert!(signer::address_of(owner_signer) == DeltaHedgingStakingV2Storage::get_admin_view(), 2);
        let old_total_stapt = DeltaHedgingStakingV2Storage::get_total_stapt_view();
        router::deposit_and_stake_entry(
            owner_signer,
            amount,
            signer::address_of(owner_signer)
        );

        let current_stapt_user_staked = DeltaHedgingStakingV2Storage::get_user_stake_view(user_address);
        let new_total_stapt = DeltaHedgingStakingV2Storage::get_total_stapt_view();
        let new_stapt_user_staked = current_stapt_user_staked + 
                                    new_total_stapt - old_total_stapt;
                                    
        DeltaHedgingStakingV2Storage::set_user_stake(
            owner_signer,
            user_address,
            new_stapt_user_staked,
            false
        );
    }

    public entry fun unstake(
        owner_signer: &signer,
        user_address: address,
    ) {
        let current_stapt_user_staked = DeltaHedgingStakingV2Storage::get_user_stake_view(user_address);
        assert!(current_stapt_user_staked > 0, 0);
        assert!(signer::address_of(owner_signer) == DeltaHedgingStakingV2Storage::get_admin_view(), 2);
        router::unstake_entry(
            owner_signer,
            current_stapt_user_staked, 
            signer::address_of(owner_signer)
        );
        DeltaHedgingStakingV2Storage::set_user_stake(
            owner_signer,
            user_address, 
            0,
            true
            );
        
        swap_amAPT_to_APT(
            owner_signer,
            DeltaHedgingStakingV2Storage::get_amapt_from_stapt_view(current_stapt_user_staked)
        );
    }

    // With Cellana 

    public entry fun swap_amAPT_to_USDC(
        owner_signer: &signer,
        amount: u64,
    ) {
        assert!(amount > 0, 0);
        assert!(signer::address_of(owner_signer) == DeltaHedgingStakingV2Storage::get_admin_view(), 2);
        
        let amount_out_min = DeltaHedgingStakingV2Storage::get_usdc_from_amapt_view(amount);

        let apt = object::address_to_object<Metadata>(APT_ADDRESS);
        let lz_usdt = object::address_to_object<Metadata>(LZ_USDT_ADDRESS);
        let usdt = object::address_to_object<Metadata>(USDT_ADDRESS);
        let usdc = object::address_to_object<Metadata>(USDC_ADDRESS);
        cellana::router::swap_route_entry_from_coin<AmnisApt>(
            owner_signer,
            amount,
            amount_out_min,
            vector[apt, usdc],
            vector[true, false],
            signer::address_of(owner_signer)
        );
    }

    public entry fun swap_amAPT_to_APT(
        owner_signer: &signer,
        amount: u64,
    ) {
        assert!(amount > 0, 0);
        assert!(signer::address_of(owner_signer) == DeltaHedgingStakingV2Storage::get_admin_view(), 2);
        
        let amount_out_min = DeltaHedgingStakingV2Storage::get_apt_from_amapt_view(amount);

        let apt = object::address_to_object<Metadata>(APT_ADDRESS);
        cellana::router::swap_route_entry_both_coins<AmnisApt, AptosCoin>(
            owner_signer,
            amount,
            amount_out_min,
            vector[apt],
            vector[true],
            signer::address_of(owner_signer)
        );
    }

    public entry fun swap_APT_to_USDC_hyperion<AptosCoin>(
        owner_signer: &signer,
        amount: u64
        ) {
        assert!(amount > 0, 0);
        assert!(signer::address_of(owner_signer) == DeltaHedgingStakingV2Storage::get_admin_view(), 2);

        let amount_out_min = DeltaHedgingStakingV2Storage::get_apt_usdc_price_hyperion_2(
            amount, 
            1
        );

        let apt = object::address_to_object<Metadata>(APT_ADDRESS);
        let usdc = object::address_to_object<Metadata>(USDC_ADDRESS);

        router_v3::swap_batch(
            owner_signer,
            vector[APT_USDT_LP_ADR, USDT_USDC_LP_ADR],
            apt,
            usdc,
            amount,
            amount_out_min,
            signer::address_of(owner_signer)
        );
        }
    
    public fun get_amount_out_X_to_Y_hyperion(
        owner_signer: &signer,
        amount: u64,
        coin_from: u8,
        coin_to: u8,
        slippage_type: u8
    ): u64 {
        assert!(amount > 0);
        assert!(signer::address_of(owner_signer) == DeltaHedgingStakingV2Storage::get_admin_view(), 2);

        DeltaHedgingStakingV2Storage::set_swap_information_in_hyperion(
            owner_signer,
            coin_from,
            coin_to,
            slippage_type
        );

        let ans = DeltaHedgingStakingV2Storage::get_X_Y_price_hyperion(
            amount
        );
        ans
    }

    public entry fun swap_X_To_Y_Hyperion(
        owner_signer: &signer,
        amount: u64,
        coin_from: u8,
        coin_to: u8,
        slippage_type: u8
    ) {
        assert!(amount > 0);
        assert!(signer::address_of(owner_signer) == DeltaHedgingStakingV2Storage::get_admin_view(), 2);
        let amount_out_min = get_amount_out_X_to_Y_hyperion(
            owner_signer,
            amount,
            coin_from,
            coin_to,
            slippage_type
        );

        router_v3::swap_batch(
            owner_signer,
            DeltaHedgingStakingV2Storage::get_adr(),
            DeltaHedgingStakingV2Storage::get_coin_from(),
            DeltaHedgingStakingV2Storage::get_coin_to(),
            amount,
            amount_out_min,
            signer::address_of(owner_signer)
        );
    }
        
}
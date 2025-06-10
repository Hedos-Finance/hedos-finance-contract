module hello_aptos_network::DeltaHedgingStakingV2 {

    use hello_aptos_network::DeltaHedgingStakingV2Storage;

    use std::signer;

    use amnis::router;
    use amnis::stapt_token;
    use amnis::delegation_manager;
    use amnis::amapt_token::AmnisApt;

    use aptos_framework::aptos_coin::AptosCoin;


    use liquidswap_v05::curves::Uncorrelated;

    use wrappedcoins::wrapped_coins::WrappedUSDC;

    const PRECISION: u128 = 100000000;
    // force 1 APT = 1 AMAPT

    public entry fun stake(
        owner_signer: &signer,
        user_address: address,
        amount: u64
    ) {
        router::deposit_and_stake_entry(
            owner_signer,
            amount,
            signer::address_of(owner_signer)
        );

        let current_stapt_user_staked = DeltaHedgingStakingV2Storage::get_user_stake_view(user_address);
        let current_stapt_total_staked = DeltaHedgingStakingV2Storage::get_total_stake_view();
        let stake_apt_fee = delegation_manager::current_add_stake_fee(amount);
        let amapt_staked = amount - stake_apt_fee;
        let stapt_amapt = (PRECISION * (amapt_staked as u128) / (stapt_token::stapt_price() as u128) ) as u64;

        let new_user_stake = current_stapt_user_staked + stapt_amapt;
        let new_total_stake = current_stapt_total_staked + stapt_amapt;
        DeltaHedgingStakingV2Storage::set_user_stake(
            owner_signer,
            user_address,
            new_user_stake,
            false
        );
        DeltaHedgingStakingV2Storage::set_total_stake(
            owner_signer,
            new_total_stake
        );
    }

    public entry fun unstake(
        owner_signer: &signer,
        user_address: address,
    ) {
        let current_user_stake = DeltaHedgingStakingV2Storage::get_user_stake_view(user_address);
        assert!(current_user_stake > 0,);
        router::unstake_entry(
            owner_signer,
            current_user_stake, 
            signer::address_of(owner_signer)
        );
        let current_total_stake = DeltaHedgingStakingV2Storage::get_total_stake_view();
        let new_total_stake = current_total_stake - current_user_stake;
        DeltaHedgingStakingV2Storage::set_total_stake(
            owner_signer,
            new_total_stake
            );

        
        DeltaHedgingStakingV2Storage::set_user_stake(
            owner_signer,
            user_address, 
            0,
            false
            );
        
        let amapt_apapt = ((current_user_stake as u128) * (stapt_token::stapt_price() as u128) / PRECISION) as u64;
        pancakeswap::router::swap_exact_input<AmnisApt, AptosCoin>
        (
            owner_signer,
            amapt_apapt,
            amapt_apapt * 990 / 1000
        );
        let apt_reward = amapt_apapt * 990 / 1000;
        DeltaHedgingStakingV2Storage::set_total_apt(
            owner_signer,
            DeltaHedgingStakingV2Storage::get_total_apt_view() + apt_reward
        );
    }

    #[view]
    public fun get_overall_staking_pool_price(
    ): u64 {
        let total_stake = DeltaHedgingStakingV2Storage::get_total_stake_view(); //stapt
        let total_apt = DeltaHedgingStakingV2Storage::get_total_apt_view(); //apt
        let amapt_apapt = ((total_stake as u128) * PRECISION / (stapt_token::stapt_price() as u128)) as u64;
        let total_apt_price = amapt_apapt + total_apt;
        if(total_apt_price == 0) {
            0
        } else {
        // let price = multi_router::router::get_amount_out<
        //     AptosCoin, 
        //     WrappedUSDC, 
        //     Uncorrelated
        //     > (total_apt_price, 0x05);
        total_apt_price
        }
    }

    public entry fun swap_APT_to_USDC(
        owner_signer: &signer,
        amount: u64
    ) {
        let total_apt = DeltaHedgingStakingV2Storage::get_total_apt_view();
        assert!(total_apt >= amount, 1);
        let new_total_apt = total_apt - amount;
        DeltaHedgingStakingV2Storage::set_total_apt(
            owner_signer,
            new_total_apt
        );

        // let price = multi_router::router::get_amount_out<
        //     AptosCoin, 
        //     WrappedUSDC, 
        //     Uncorrelated
        //     >(amount, 0x05);
        let price = 1;
        multi_router::router::fa_swap_exact_coin_for_coin_x1<
            AptosCoin,
            WrappedUSDC,
            Uncorrelated,
            multi_router::router::BinStepV0V05
        >(
            owner_signer,
            amount,
            vector[price * 990 / 1000],
            vector[0x05],
            vector[true]
            );
    }
}
module hedos::liquid_actions {
    use hedos::token::{get_apt_balance, get_amAPT_balance, get_stAPT_balance};
    use hedos::interact_hyperion::{hyperion_swap_X_To_Y, get_amount_in};
    use hedos::interact_amnis::{stake, unstake_amAPT, price_stAPT};
    use std::signer;

    const USDC_CHOOSEN: u8 = 1;
    const APT_CHOOSEN: u8 = 2;
    const AMAPT_CHOOSEN: u8 = 3;

    const PRECISION: u128 = 100000000;

    public entry fun liquid_staking(owner: &signer, amountUSDC: u64) {
        let account = signer::address_of(owner);
        
        let amount_stake_before = get_apt_balance(account);
        hyperion_swap_X_To_Y(owner, amountUSDC, USDC_CHOOSEN, APT_CHOOSEN);
        let amount_stake_after = get_apt_balance(account) ;
        let amount_stake = amount_stake_after - amount_stake_before;

        stake(owner, amount_stake, account);
    }

    public entry fun liquid_staking_unstake(owner: &signer, amountUSDC: u64) {
        let account = signer::address_of(owner);
        
        let amApt_unstake = get_amount_in(amountUSDC, AMAPT_CHOOSEN, USDC_CHOOSEN);
        
        let st_unstake = (PRECISION * (amApt_unstake as u128) / (price_stAPT() as u128) ) as u64;

        let amAPT_balance_before = get_amAPT_balance(account);
        unstake_amAPT(owner, st_unstake, account);
        let amAPT_balance_after = get_amAPT_balance(account);

        hyperion_swap_X_To_Y(owner, amAPT_balance_after - amAPT_balance_before, AMAPT_CHOOSEN, USDC_CHOOSEN);
    }

    public entry fun liquid_staking_unstake_all(owner: &signer) {
        let account = signer::address_of(owner);    

        let stAPT_balance = get_stAPT_balance(account);
        unstake_amAPT(owner, stAPT_balance, account);
        
        let amAPT_balance = get_amAPT_balance(account);
        hyperion_swap_X_To_Y(owner, amAPT_balance, AMAPT_CHOOSEN, USDC_CHOOSEN);
    }
}
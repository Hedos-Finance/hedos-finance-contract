module hedos::lending_actions {
    use hedos::interact_aries::{deposit, deposit_fa, withdraw, withdraw_fa, repay, total_loaning, total_lending, get_borrow_amount};
    use hedos::interact_hyperion::{hyperion_swap_X_To_Y, get_amount_in};
    use hedos::token::{get_apt_balance};

    use std::signer;
    use std::string::{String, utf8};

    use wrapped_coins::wrapped_coins::WrappedUSDC;
    use aptos_framework::aptos_coin::AptosCoin;

    const USDC_CHOOSEN: u8 = 1;
    const APT_CHOOSEN: u8 = 2;
    const AMAPT_CHOOSEN: u8 = 3;

    public entry fun lending_deposit(owner: &signer, amount: u64, token: String) {
        if (token == utf8(b"USDC")) {
            deposit_fa<WrappedUSDC>(owner, amount);
        } else if (token == utf8(b"APT")) {
            deposit<AptosCoin>(owner, amount, false);
        } else {
            abort 1;
        };
    }

    public entry fun lending_borrow(owner: &signer, amountAPT: u64) {
        withdraw<AptosCoin>(owner, amountAPT, true);
    }

    public entry fun lending_deposit_and_borrow(owner: &signer, amountUSDC: u64, amountAPT_borrow: u64) {
        deposit_fa<WrappedUSDC>(owner, amountUSDC);
        withdraw<AptosCoin>(owner, amountAPT_borrow, true);
    }

    public entry fun lending_deposit_and_borrow_by_rate(owner: &signer, amountUSDC: u64, rate: u64) {
        let (_, amountAPT_borrow) = get_borrow_amount<WrappedUSDC, AptosCoin>(amountUSDC, rate);

        deposit_fa<WrappedUSDC>(owner, amountUSDC);
        withdraw<AptosCoin>(owner, amountAPT_borrow, true);
    }
    
    public entry fun lending_repay(owner: &signer, amountAPT: u64) {
        repay<AptosCoin>(owner, amountAPT);
    }

    public entry fun lending_withdraw(owner: &signer, amount: u64, token: String) {
        if (token == utf8(b"USDC")) {
            withdraw_fa<WrappedUSDC>(owner, amount, false);
        } else if (token == utf8(b"APT")) {
            withdraw<AptosCoin>(owner, amount, false);
        } else {
            abort 1;
        };
    }

    public entry fun lending_repay_and_withdraw(owner: &signer, amountAPT_repay: u64, amountUSDC_withdraw: u64) {
        repay<AptosCoin>(owner, amountAPT_repay);
        withdraw_fa<WrappedUSDC>(owner, amountUSDC_withdraw, false);
    }

    public entry fun lending_repay_all(owner: &signer) {
        let amountAPT_repay = total_loaning<AptosCoin>(signer::address_of(owner)) + 1;
        
        let apt_balance = get_apt_balance(signer::address_of(owner));

        if (apt_balance < amountAPT_repay) {
            let amount_in = get_amount_in(amountAPT_repay - apt_balance, USDC_CHOOSEN, APT_CHOOSEN);
            hyperion_swap_X_To_Y(owner, amount_in, USDC_CHOOSEN, APT_CHOOSEN);
        };

        repay<AptosCoin>(owner, amountAPT_repay);
    }

    public entry fun lending_repay_and_withdraw_all(owner: &signer) {
        lending_repay_all(owner);
        let amountUSDC_withdraw = total_lending<WrappedUSDC>(signer::address_of(owner));
        withdraw_fa<WrappedUSDC>(owner, amountUSDC_withdraw, false);
    }
}
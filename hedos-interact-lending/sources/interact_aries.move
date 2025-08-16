module hedos::interact_aries {
    use std::string;

    use oracle::oracle;
    use decimal::decimal;

    use aries::controller;
    use aries::profile;

    const NAME_BYTES: vector<u8> = x"4d61696e204163636f756e74";
    const USDC_Multiplier: u128 = 1000000000000;            // 1e12
    const APT_Multiplier: u128 = 10000000000;               // 1e10
    const Multiplier: u128 = 1000000;                       // 1e6
    const Multiplier_2: u128 = 100000000;                   // 1e8
    const Max_Multiplier: u128 = 100000000000000000000000000; // 1e26

    public entry fun register_user(
        account: &signer
    ) {
        controller::register_user(account, NAME_BYTES);
    }
    
    #[view]
    public fun get_price<Coin0>(): u128 {
        let ans = decimal::raw(oracle::get_reserve_price<Coin0>());
        ans
    }

    #[view]
    public fun get_decimal_price<Coin0>(): decimal::Decimal {
        let ans = oracle::get_reserve_price<Coin0>();
        ans
    }

    #[view]
    public fun total_lending<Coin0>(account: address): u64 {
        let (_, total_lending) = profile::profile_deposit<Coin0>(
            account,
            string::utf8(NAME_BYTES)
        );
        total_lending
    }

    #[view]
    public fun total_loaning<Coin0>(account: address): u64 {
        let (_, total_loaning) = profile::profile_loan<Coin0>(
            account,
            string::utf8(NAME_BYTES)
        );
        (total_loaning * Multiplier_2 / Max_Multiplier) as u64
    }

    public entry fun deposit<Coin0>(
        owner_signer: &signer,
        amount: u64,
        repay_only: bool
    ) {
        controller::deposit<Coin0>(
            owner_signer,
            NAME_BYTES,
            amount,
            repay_only
        );
    }

    public entry fun withdraw<Coin0>(
        owner_signer: &signer,
        amount: u64,
        allow_borrow: bool
    ) {
        controller::withdraw<Coin0>(
            owner_signer,
            NAME_BYTES,
            amount,
            allow_borrow
        );
    }

    public entry fun deposit_fa<Coin0>(
        owner_signer: &signer,
        input_amount: u64
    ) {
        controller::deposit_fa<Coin0>(
            owner_signer,
            NAME_BYTES,
            input_amount
        );
    }

    public entry fun withdraw_fa<Coin0>(
        owner_signer: &signer,
        input_amount: u64,
        allow_borrow: bool
    ) {
        controller::withdraw_fa<Coin0>(
            owner_signer,
            NAME_BYTES,
            input_amount,
            allow_borrow
        );
    }

    public entry fun repay<Coin1>(
        owner_signer: &signer,
        repay_amount_want: u64
    ) {
        controller::deposit<Coin1>(
            owner_signer,
            NAME_BYTES,
            repay_amount_want,
            true
        );
    }

    // can use with only pair <USDC/APT>
    // public fun deposit_and_borrow<Coin0, Coin1>(
    //     _owner_signer: &signer,
    //     input_amount: u64,
    //     collateral_want: u64
    // ): (u64, u64) {

    //     let coin0_price = get_price<Coin0>();
    //     let coin1_price = get_price<Coin1>() * 10000;

    //     let borrow_amount = (input_amount as u128) 
    //                         * (coin0_price as u128) 
    //                         * (collateral_want as u128) 
    //                         / (coin1_price as u128);

    //     (input_amount, borrow_amount as u64)
    // }

    public entry fun deposit_and_borrow_rate<Coin0, Coin1>(
        owner_signer: &signer,
        input_amount: u64,
        collateral_want: u64
    ) {

        let coin0_price = get_price<Coin0>();
        let coin1_price = get_price<Coin1>() * 10000;

        let borrow_amount = (input_amount as u128) 
                            * (coin0_price as u128) 
                            * (collateral_want as u128) 
                            / (coin1_price as u128);
        
        controller::deposit_fa<Coin0>(
            owner_signer,
            NAME_BYTES,
            input_amount
        );
        
        controller::withdraw<Coin1>(
            owner_signer,
            NAME_BYTES,
            borrow_amount as u64,
            true
        );
    }

    #[view]
    public fun get_borrow_amount<Coin0, Coin1>(
        input_amount: u64,
        collateral_want: u64
    ): (u64, u64) {

        let coin0_price = get_price<Coin0>();
        let coin1_price = get_price<Coin1>() * 10000;

        let borrow_amount = (input_amount as u128) 
                            * (coin0_price as u128) 
                            * (collateral_want as u128) 
                            / (coin1_price as u128);

        (input_amount, borrow_amount as u64)
    }

    // cai true/false trong truong hop deposit la option co/khong gui tai san lam collateral
    // false: 
    // user co khoan vay -> uu tien tra no
    // tien thua tu vc tra no / ng dung khong no truoc do -> collateral
    // true:
    // user co khoan vay -> tra no
    // tien thua tu vc tra no / nguoi dung khong no truoc do -> tra lai cho user

    // true / false trong truong hop withdraw la option co/khong rut qua phan da deposit
    // false:
    // user co collateral < amount -> khong rut duoc
    // user co collateral >= amount -> rut duoc
    // true:
    // user co collateral < amount -> rut duoc (phan thieu chuyen thanh khoan vay)
    // user co collateral >= amount -> rut binh thuong
}
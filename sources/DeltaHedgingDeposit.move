module hello_aptos_network::DeltaHedgingDeposit {

    use hello_aptos_network::DeltaHedgingStakingV2Storage;

    use std::signer;
    use std::string;
    use std::vector;

    use aptos_framework::object::{Self};
    use aptos_framework::aptos_coin::AptosCoin;

    use aries::controller;
    use aries::profile;

    const NAME_BYTES: vector<u8> = x"4d61696e204163636f756e74";

    // cai true/false trong truong hop deposit la option co/khong gui tai san lam collateral
    // false: 
    // user co khoan vay -> uu tien tra no
    // tien thua tu vc tra no / ng dung khong no truoc do -> collateral
    // true:
    // user co khoan vay -> tra no
    // tien thua tu vc tra no / nguoi dung khong no truoc do -> tra lai cho user

    public entry fun deposit(
        owner_signer: &signer,
        amount: u64
    ) {
        assert!(amount > 0, 0);
        assert!(signer::address_of(owner_signer) == hello_aptos_network::DeltaHedgingStakingV2Storage::get_admin_view(), 1);
        assert!(amount <= DeltaHedgingStakingV2Storage::get_total_apt_view(), 2);

        controller::deposit<AptosCoin>(
            owner_signer,
            NAME_BYTES,
            amount,
            false
        );
    }

    // true / false trong truong hop withdraw la option co/khong rut qua phan da deposit
    // false:
    // user co collateral < amount -> khong rut duoc
    // user co collateral >= amount -> rut duoc
    // true:
    // user co collateral < amount -> rut duoc (phan thieu chuyen thanh khoan vay)
    // user co collateral >= amount -> rut binh thuong

    public entry fun withdraw(
        owner_signer: &signer,
        amount: u64
    ) {
        assert!(amount > 0, 0);
        assert!(signer::address_of(owner_signer) == hello_aptos_network::DeltaHedgingStakingV2Storage::get_admin_view(), 1);

        controller::withdraw<AptosCoin>(
            owner_signer,
            NAME_BYTES,
            amount,
            false
        );
    }

    #[view]
    public fun total_lending(): u64 {
        let (total_collateral, total_apt_lending) = profile::profile_deposit<AptosCoin>(
            @hello_aptos_network,
            string::utf8(NAME_BYTES)
        );
        total_apt_lending
    }

    #[view]
    public fun total_loaning()  : u128 {
        let (total_collateral, total_apt_loaning) = profile::profile_loan<AptosCoin>(
            @hello_aptos_network,
            string::utf8(NAME_BYTES)
        );
        total_apt_loaning
    }
}
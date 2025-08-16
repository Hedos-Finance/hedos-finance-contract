module hedos::white_list {
    use std::signer;
    use aptos_std::smart_vector::{Self, SmartVector};

    const HEDOS: address = @hedos;

    const NOT_HEDOS: u64 = 999;
    const NOT_ADMIN: u64 = 998;

    struct WhiteList has key {
        admin_list: SmartVector<address>,
    }

    public entry fun init_white_list(signer: &signer) {
        assert!(signer::address_of(signer) == HEDOS, NOT_HEDOS);
        let white_list = smart_vector::new<address>();
        smart_vector::push_back(&mut white_list, HEDOS);
        move_to(signer, WhiteList { admin_list: white_list });
    }

    public entry fun add_admin(signer: &signer, admin: address) acquires WhiteList {
        only_admin(signer);
        let (found, _) = smart_vector::index_of(&borrow_global<WhiteList>(HEDOS).admin_list, &admin);
        if (!found) {
            smart_vector::push_back(&mut borrow_global_mut<WhiteList>(HEDOS).admin_list, admin);
        }
    }

    public entry fun remove_admin(signer: &signer, admin: address) acquires WhiteList {
        only_admin(signer);
        let (found, index) = smart_vector::index_of(&borrow_global<WhiteList>(HEDOS).admin_list, &admin);
        if (found) {
            smart_vector::remove(&mut borrow_global_mut<WhiteList>(HEDOS).admin_list, index);
        }
    }

    public fun only_admin(signer: &signer) acquires WhiteList {
        let address_of_signer = signer::address_of(signer);
        let is_admin = smart_vector::contains(&borrow_global<WhiteList>(HEDOS).admin_list, &address_of_signer);
        assert!(is_admin, NOT_ADMIN);
    }
}
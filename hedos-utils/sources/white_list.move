module hedos::white_list {
    use std::signer;
    use aptos_std::smart_vector::{Self, SmartVector};

    const HEDOS: address = @hedos;

    /// Caller not hedos
    const NOT_HEDOS: u64 = 999;
    /// Caller not admin
    const NOT_ADMIN: u64 = 998;

    struct WhiteList has key {
        admin_list: SmartVector<address>
    }

    public entry fun init_white_list(signer: &signer) {
        assert!(signer::address_of(signer) == HEDOS, NOT_HEDOS);
        let white_list = smart_vector::new<address>();
        white_list.push_back(HEDOS);
        move_to(signer, WhiteList { admin_list: white_list });
    }

    public entry fun add_admin(signer: &signer, admin: address) acquires WhiteList {
        only_owner(signer);
        let (found, _) = borrow_global<WhiteList>(HEDOS).admin_list.index_of(&admin);
        if (!found) {
            borrow_global_mut<WhiteList>(HEDOS).admin_list.push_back(admin);
        }
    }

    public entry fun remove_admin(signer: &signer, admin: address) acquires WhiteList {
        only_owner(signer);
        let (found, index) = borrow_global<WhiteList>(HEDOS).admin_list.index_of(&admin);
        if (found) {
            borrow_global_mut<WhiteList>(HEDOS).admin_list.remove(index);
        }
    }

    public fun only_owner(signer: &signer) {
        assert!(signer::address_of(signer) == HEDOS, NOT_HEDOS);
    }

    public fun only_admin(signer: &signer) acquires WhiteList {
        let address_of_signer = signer::address_of(signer);
        let is_admin =
            borrow_global<WhiteList>(HEDOS).admin_list.contains(&address_of_signer);
        assert!(is_admin, NOT_ADMIN);
    }
}


module aries::profile {

use std::string;

public fun profile_deposit<ReserveType>(
    user_addr: address, 
    profile_name: string::String
    ): (u64, u64) {
        abort(0)
    }

public fun profile_loan<ReserveType>(
    user_addr: address, 
    profile_name: string::String
    ): (u128, u128) {
        abort(0)
    }
}
module delta_hedging::math256 {
    struct I256 has copy, drop, store {
        value: u256,
        is_negative: bool,
    }

    public fun init_i256(value: u256, is_negative: bool): I256 {
        I256 { value, is_negative }
    }

    public fun get_value_256(a: I256): u256 {
        a.value
    }

    public fun is_negative_256(a: I256): bool {
        a.is_negative
    }

    public fun add_256(a: I256, b: I256): I256 {
        let result: u256;
        let is_negative: bool;

        if (a.is_negative == b.is_negative) {
            is_negative = a.is_negative;
            result = a.value + b.value;
        }
        else {
            if (a.value > b.value) {
                is_negative = a.is_negative;
                result = a.value - b.value;
            }
            else {
                is_negative = b.is_negative;
                result = b.value - a.value;
            };
        };
        if (result == 0) {
            is_negative = false;
        };
        I256 { value: result, is_negative }
    }

    public fun sub_256(a: I256, b: I256): I256 {
        let result: u256;
        let is_negative: bool;

        if (a.is_negative != b.is_negative) {
            is_negative = a.is_negative;
            result = a.value + b.value;
        }
        else {
            if (a.value > b.value) {
                is_negative = a.is_negative;
                result = a.value - b.value;
            }
            else {
                is_negative = !a.is_negative;
                result = b.value - a.value;
            };
        };

        if (result == 0) {
            is_negative = false;
        };

        I256 { value: result, is_negative }
    }
    
    public fun safe_sub_u256(a: u256, b: u256): u256 {
        if (a > b) {
            a - b
        } else {
            0
        }
    }
}
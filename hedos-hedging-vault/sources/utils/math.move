module delta_hedging::math {
    struct I64 has copy, drop, store {
        value: u64,
        is_negative: bool,
    }

    public fun init_i64(value: u64, is_negative: bool): I64 {
        I64 { value, is_negative }
    }

    public fun get_value(a: I64): u64 {
        a.value
    }

    public fun is_negative(a: I64): bool {
        a.is_negative
    }

    public fun add(a: I64, b: I64): I64 {
        let result: u64;
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
        I64 { value: result, is_negative }
    }

    public fun sub(a: I64, b: I64): I64 {
        let result: u64;
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

        I64 { value: result, is_negative }
    }

    public fun safe_sub(a: u64, b: u64): u64 {
        if (a > b) {
            a - b
        } else {
            0
        }
    }
    
}
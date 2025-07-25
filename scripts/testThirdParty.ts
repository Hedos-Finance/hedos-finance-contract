import { aptos, getSigner } from "./aptos_utils";
import {
    Account,
    Aptos,
    AptosConfig,
    Ed25519PrivateKey,
    HexInput,
    Network,
    NetworkToNetworkName,
    InputViewFunctionData 
} from "@aptos-labs/ts-sdk";

const ACCOUNT = "0x0b1aeace2c12b282262fefc510704f2b37dca678fe7bdc3794628c5eaabc76dd";
const MODULE = "third_party";

async function test() {
    const signer = await getSigner();

    console.log("Address:", signer.accountAddress);
    console.log("Signer:", signer);

    const perpPayload: InputViewFunctionData  = {
        function: `${ACCOUNT}::${MODULE}::new_perp_v2`,
        typeArguments: [],
        functionArguments: [
            "2000000",      // collateral_delta: u64
            "150",          // leverage: u64
            true,           // is_long: bool
            false,          // market_skew: bool
            false,          // is_open: bool
			      true            // is_official: bool
        ],
    };
    const perp = await aptos.view({payload: perpPayload});

    const liquidPayload: InputViewFunctionData  = {
        function: `${ACCOUNT}::${MODULE}::new_liquid_v2`,
        typeArguments: [],
        functionArguments: [
            "1000000",        // amount_withdraw: u64         
            false,          // is_open: bool
			      true            // is_official: bool
        ],
    };
    const liquid = await aptos.view({payload: liquidPayload});

    const USDC = 'USDC';
    const APT = 'APT';

    const lendingPayload: InputViewFunctionData  = {
        function: `${ACCOUNT}::${MODULE}::new_lending_v2`,
        typeArguments: [],
        functionArguments: [
            "1000000",      // amount_withdraw: u64
            USDC,         // token_withdraw: String
            "1000000",      // amount_repay: u64
            APT,          // token_repay: String
            "1",               // action: u8:             
            false,          // is_open: bool
			      true            // is_official: bool
            
        ],
    };
    const lending = await aptos.view({payload: lendingPayload});


    console.log("perp:", perp);
    console.log("liquid:", liquid);
    console.log("lending:", lending);

    let merged = JSON.stringify([...lending, ...lending, ...liquid].flat());
    console.log(merged);

    const checkPayload: InputViewFunctionData  = {
        function: `${ACCOUNT}::${MODULE}::check_unzip`,   
        typeArguments: [],
        functionArguments: [
            merged
        ],
    };

    const check = await aptos.view({payload: checkPayload});    
    console.log("check:", check);
    
}


async function main() {
    await test();
}

main();
import { aptos, getSigner } from "./aptos_utils";
import {
    Account,
    Aptos,
    AptosConfig,
    Ed25519PrivateKey,
    HexInput,
    Network,
    NetworkToNetworkName
} from "@aptos-labs/ts-sdk";

const ACCOUNT = process.env.APTOS_ACCOUNT;
const MODULE = "general_vault";
const token = "token";
const address_user = "0b625e2c4582203073b54cded720782bd87b059ba98d8229177baf16b969c5d9";
async function get_function() {
    let payload;
    let result;
    payload = {
        function: `${ACCOUNT}::${MODULE}::get_vault_address`,
        typeArguments: [],
        functionArguments: [],
    };
    result = await aptos.view({ payload });

    console.log("address vault", `${result}`);

    payload = {
        function: `${ACCOUNT}::${MODULE}::get_total_value_lock`,
        typeArguments: [],
        functionArguments: [],
    };
    result = await aptos.view({ payload });

    console.log("TVL vault", `${result}`);

    payload = {
        function: `${ACCOUNT}::${MODULE}::get_total_staked`,
        typeArguments: [],
        functionArguments: [],
    };
    result = await aptos.view({ payload });

    console.log("staked vault", `${result}`);

        payload = {
        function: `${ACCOUNT}::${MODULE}::get_total_perpeptual`,
        typeArguments: [],
        functionArguments: [],
    };
    result = await aptos.view({ payload });

    console.log("perp vault", `${result}`);

    payload = {
        function: `${ACCOUNT}::${MODULE}::total_share`,
        typeArguments: [],
        functionArguments: [],
    };
    result = await aptos.view({ payload });

    console.log("total share", `${result}`);

    payload = {
        function: `${ACCOUNT}::${MODULE}::user_share`,
        typeArguments: [],
        functionArguments: [address_user],
    };
    result = await aptos.view({ payload });

    console.log("user share", `${result}`);
}

async function get_total_share() {
    let payload;
    payload = {
        function: `${ACCOUNT}::${MODULE}::total_share`,
        typeArguments: [],
        functionArguments: [],
    };
    let result = await aptos.view({ payload });

    console.log("address vault", `${result}`);


}

async function get_balance() {
    let payload;
    payload = {
        function: `${ACCOUNT}::${MODULE}::get_apt_balance`,
        typeArguments: [],
        functionArguments: ["0x9686413a6e3058c175c6da220ada516fde4c499952767f475b6bb907555d1f4b"],
    };
    let result = await aptos.view({ payload });

    console.log("address vault", `${result}`);


}

async function get_balance_usdc() {
    let payload;
    payload = {
        function: `${ACCOUNT}::${token}::get_usdc_balance`,
        typeArguments: [],
        functionArguments: ["0x018f8c33d241c6f4e9dc388b37960d36ff30ce5d7ea4a17d123857b5bb70277b"],
    };
    let result = await aptos.view({ payload });

    console.log("address vault", `${result}`);
}

async function get_total_stake() {
    let payload;
    payload = {
        function: `${ACCOUNT}::${MODULE}::`,
        typeArguments: [],
        functionArguments: ["0xd5681ec72873e61d6b21fae75ab58d53a7935f42157a910e0343c72970e183cb"],
    };
    let result = await aptos.view({ payload });

    console.log("address vault", `${result}`);
}

async function get_fund_fee() {
    let payload;
    payload = {
        function: `${ACCOUNT}::${MODULE}::`,
        typeArguments: [],
        functionArguments: [],
    };
    let result = await aptos.view({ payload });

    console.log("address vault", `${result}`);
}
async function main() {
    // await get_balance();
    // await get_balance_usdc();
    // await get_total_stake();
    await get_function();
    // await get_total_share();
}

main();
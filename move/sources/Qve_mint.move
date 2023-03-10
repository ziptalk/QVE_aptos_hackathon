module Qve::mint {
    use std::signer;
    use std::string;
    use std::vector;
    use std::error;
    use aptos_std::debug;

    use aptos_framework::account::{Self, SignerCapability};
    use aptos_framework::coin::{Self, Coin, MintCapability, FreezeCapability, BurnCapability};
    use aptos_framework::resource_account;
    use aptos_framework::aptos_coin::{AptosCoin};
    use aptos_framework::aptos_account;
    use aptos_std::simple_map::{Self, SimpleMap};

    const EPOOL: u64 = 0;
    const ENO_CAPABILITIES: u64 = 1;
    const EINSUFFICIENT_BALANCE: u64 = 2;

    struct ArbQVE {
        aptos_coin:AptosCoin
    }

    struct QVE {
        aptos_coin:AptosCoin
    }

    // struct Coin<phantom CoinType> {
    //     value: u64,
    // }

    struct ModuleData has key {
        resource_signer_cap_qv: account::SignerCapability,
        burn_cap_qv: BurnCapability<QVE>,
        mint_cap_qv: MintCapability<QVE>,
        resource_signer_cap_arbqv: account::SignerCapability,
        burn_cap_arbqv: BurnCapability<ArbQVE>,
        mint_cap_arbqv: MintCapability<ArbQVE>,
    }

    fun init_module(account: &signer) {

        let (resource_signer_qv, resource_signer_cap_qv) = account::create_resource_account(account, b"resource_init_qv");
        let (resource_signer_arbqv, resource_signer_cap_arbqv) = account::create_resource_account(account, b"resource_init_arbqv");

        let (burn_cap_qv, freeze_cap_qv, mint_cap_qv) = coin::initialize<QVE>(
            account,
            string::utf8(b"QVE"),
            string::utf8(b"QVE"),
            8,
            false
        );
        let (burn_cap_arbqv, freeze_cap_arbqv, mint_cap_arbqv) = coin::initialize<ArbQVE>(
            account,
            string::utf8(b"arbQVE"),
            string::utf8(b"arbQVE"),
            8,
            false
        );
        
        move_to(account, ModuleData {
            resource_signer_cap_qv,
            burn_cap_qv,
            mint_cap_qv,
            resource_signer_cap_arbqv,
            burn_cap_arbqv,
            mint_cap_arbqv,
        });

        coin::destroy_freeze_cap(freeze_cap_qv);
        coin::destroy_freeze_cap(freeze_cap_arbqv);

        coin::register<AptosCoin>(account);
        coin::register<QVE>(account);
        coin::register<ArbQVE>(account);
    }

    public fun exchange_to(b_coin: Coin<AptosCoin>): Coin<ArbQVE> acquires ModuleData {
        let coin_cap = borrow_global_mut<ModuleData>(@Qve);
        let amount = coin::value(&b_coin);
        coin::deposit(@Qve, b_coin);
        coin::mint<ArbQVE>(amount, &coin_cap.mint_cap_arbqv)
    }

    public entry fun exchange_to_entry(account: &signer, amount:u64) acquires ModuleData{
        let aptos_coin = coin::withdraw<AptosCoin>(account, amount);  // from AptosCoin
        let arbqv_coin = exchange_to(aptos_coin);  // from aptos_coin to arbQVE(arbqv_coin)

        coin::register<ArbQVE>(account);
        coin::register<QVE>(account);
        coin::deposit(signer::address_of(account), arbqv_coin);
    }
    
    public fun tmp_qve_mint(b_coin: Coin<AptosCoin>): Coin<QVE> acquires ModuleData {
        let coin_cap = borrow_global_mut<ModuleData>(@Qve);
        let amount = coin::value(&b_coin);
        coin::deposit(@Qve, b_coin);
        coin::mint<QVE>(amount, &coin_cap.mint_cap_qv)
    }

    public entry fun tmp_qve_mint_entry(account: &signer, amount:u64) acquires ModuleData{

        let aptos_coin = coin::withdraw<AptosCoin>(account, amount);  // from AptosCoin
        let qv_coin = tmp_qve_mint(aptos_coin);

        coin::register<QVE>(account);
        coin::deposit(signer::address_of(account), qv_coin);
    }
}
module Qve::qve_mint{
    use std::signer;
    use std::string;
    use std::vector;

    use aptos_framework::account;
    use aptos_framework::coin::{Self, Coin, MintCapability, FreezeCapability, BurnCapability};
    use aptos_framework::resource_account;
    use aptos_framework::aptos_coin::{AptosCoin};
    use aptos_std::simple_map::{Self, SimpleMap};

    struct ArbQVE{
        aptos_coin:AptosCoin
    }

    struct ModuleData has key {
        resource_signer_cap: account::SignerCapability,
        burn_cap: BurnCapability<ArbQVE>,
        mint_cap: MintCapability<ArbQVE>,
    }

    const ENO_CAPABILITIES: u64 = 1;

    fun init_module(account: &signer){


        let (resource_signer, resource_signer_cap) = account::create_resource_account(account, b"resource_init");

        let (burn_cap, freeze_cap, mint_cap) = coin::initialize<ArbQVE>(
            account,
            string::utf8(b"arbQVE"),
            string::utf8(b"arbQVE"),
            8,
            false
        );
     
        
        move_to(account, ModuleData {
            resource_signer_cap,
            burn_cap,
            mint_cap,
        });

        coin::destroy_freeze_cap(freeze_cap);

        coin::register<AptosCoin>(account);
        coin::register<ArbQVE>(account);
    }    

    public fun exchange_to(b_coin: Coin<AptosCoin>): Coin<ArbQVE> acquires ModuleData {
        let coin_cap = borrow_global_mut<ModuleData>(@Qve);
        let amount = coin::value(&b_coin);
        coin::deposit(@Qve, b_coin);
        coin::mint<ArbQVE>(amount, &coin_cap.mint_cap)
    }


    public entry fun exchange_to_entry(account: &signer, amount:u64) acquires ModuleData{

        let a_coin = coin::withdraw<AptosCoin>(account, amount);
        let c_coin = exchange_to(a_coin);

        coin::register<ArbQVE>(account);
        coin::deposit(signer::address_of(account), c_coin);
    }

    // public entry fun exchange_to_with_stable_entry(account: &signer, total_amount:u64, stake_amount:u64, stable_amount:u64) acquires ModuleData{

    //     let a_coin = coin::withdraw<AptosCoin>(account, total_amount-stake_amount);
    //     let b_coin = coin::withdraw<AptosCoin>(account, stake_amount);
    //     let stable_coin = coin::withdraw<AptosCoin>(account, 0);

    //     coin::deposit(@InviMove, a_coin);

    //     let c_coin = exchange_to(b_coin);
        
    //     let stable_coin = stable_hedging(stable_coin, stable_amount);
        
    //     coin::register<USDC>(account);
    //     coin::register<InAptos>(account);
    //     coin::deposit(signer::address_of(account), c_coin);
    //     coin::deposit(signer::address_of(account), stable_coin);
    // }
}
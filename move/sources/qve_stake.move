module Qve::stake {
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

    use Qve::mint::{Self, QVE, ArbQVE, ModuleData};

    const EPOOL: u64 = 0;
    const ENO_CAPABILITIES: u64 = 1;
    const EINSUFFICIENT_BALANCE: u64 = 2;
    const EZERO_TOKEN_IN_POOL: u64 = 3;

    struct Staked has key {
        coin_qve_reserve: Coin<QVE>,
        coin_arbqve_reserve: Coin<ArbQVE>,
    }

    fun init_module(account: &signer) {

        let staked = Staked {
            coin_qve_reserve: coin::zero<QVE>(),
            coin_arbqve_reserve: coin::zero<ArbQVE>(),
        };
        move_to(account, staked);

        coin::register<AptosCoin>(account);
        coin::register<QVE>(account);
        coin::register<ArbQVE>(account);
    }

    public fun getValueofPool(hi: address): (u64, u64) acquires Staked {
        let pool = borrow_global_mut<Staked>(@Qve);
        let qve_reserve = coin::value(&pool.coin_qve_reserve);
        let arbqve_reserve = coin::value(&pool.coin_arbqve_reserve);

        return (qve_reserve, arbqve_reserve)
    }

    public entry fun putQVE(account: &signer, amount: u64) acquires Staked {

        let qve_coin = coin::withdraw<QVE>(account, amount);
        let pool = borrow_global_mut<Staked>(@Qve);
        
        let x_reserve_size = coin::value(&pool.coin_qve_reserve); 
        let x_provided_val = coin::value<QVE>(&qve_coin);

        coin::merge(&mut pool.coin_qve_reserve, qve_coin); 
    }

    public entry fun putArbQVE(account: &signer, amount: u64) acquires Staked{

        let arbqve_coin = coin::withdraw<ArbQVE>(account, amount);
        let pool = borrow_global_mut<Staked>(@Qve);
        
        let y_reserve_size = coin::value(&pool.coin_arbqve_reserve); 
        let y_provided_val = coin::value<ArbQVE>(&arbqve_coin); 

        coin::merge(&mut pool.coin_arbqve_reserve, arbqve_coin);
    }

    public entry fun staked_Qve(account: &signer, amount: u64) acquires Staked {
        let stake = borrow_global_mut<Staked>(@Qve);
        // let coin_cap = borrow_global_mut<ModuleData>(@Qve);
        let staked_qve_coin = coin::withdraw<QVE>(account, amount); 
        let return_amount = amount / 10;
        // let return_qve_coin = coin::mint<QVE>(return_amount, &coin_cap.mint_cap_qv);
        // let return_qve_coin = coin::withdraw<QVE>(account, return_amount);
        // coin::deposit(signer::address_of(account), return_qve_coin);
        coin::merge(&mut stake.coin_qve_reserve, staked_qve_coin); 
    }

    public entry fun staked_arbQVE(account: &signer, amount: u64) acquires Staked {
        let stake = borrow_global_mut<Staked>(@Qve);
        // let coin_cap = borrow_global_mut<ModuleData>(@Qve);
        let staked_arbqve_coin = coin::withdraw<ArbQVE>(account, amount);
        let return_amount = amount / 10;
        // let return_arbqve_coin = coin::mint<ArbQVE>(return_amount, &coin_cap.mint_cap_arbqv);
        // let return_arbqve_coin = coin::withdraw<ArbQVE>(account, return_amount);
        // coin::deposit(signer::address_of(account), return_arbqve_coin);
        coin::merge(&mut stake.coin_arbqve_reserve, staked_arbqve_coin);
    }
}
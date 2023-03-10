module Qve::liqpool {
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
    
    use Qve::mint::{Self, QVE, ArbQVE};

    const EPOOL: u64 = 0;
    const ENO_CAPABILITIES: u64 = 1;
    const EINSUFFICIENT_BALANCE: u64 = 2;
    const EZERO_TOKEN_IN_POOL: u64 = 3;

    // /// Stores resource account signer capability under Liquidswap account.
    // struct PoolAccountCapability has key { signer_cap: SignerCapability }

    // /// Temporary storage for user resource account signer capability.
    // struct CapabilityStorage has key { signer_cap: SignerCapability }
    
    struct MessageHolder has key {
        message: string::String,
    }

    struct LiquidityPool has key {
        coin_x_reserve: Coin<QVE>,
        coin_y_reserve: Coin<ArbQVE>,
        fee: u64,  // 1 - 100 (0.01% - 1%)
    }

    fun init_module(account: &signer) {

        let pool = LiquidityPool {
            coin_x_reserve: coin::zero<QVE>(),
            coin_y_reserve: coin::zero<ArbQVE>(),
            fee: 0,
        };
        move_to(account, pool);

        coin::register<AptosCoin>(account);
        coin::register<QVE>(account);
        coin::register<ArbQVE>(account);
    }

    public entry fun putQVE(account: &signer, amount: u64) acquires LiquidityPool {

        let qve_coin = coin::withdraw<QVE>(account, amount);
        let pool = borrow_global_mut<LiquidityPool>(@Qve);
        
        let x_reserve_size = coin::value(&pool.coin_x_reserve); 
        let x_provided_val = coin::value<QVE>(&qve_coin);

        coin::merge(&mut pool.coin_x_reserve, qve_coin); 
    }

    public entry fun putArbQVE(account: &signer, amount: u64) acquires LiquidityPool{

        let arbqve_coin = coin::withdraw<ArbQVE>(account, amount);
        let pool = borrow_global_mut<LiquidityPool>(@Qve);
        
        let y_reserve_size = coin::value(&pool.coin_y_reserve); 
        let y_provided_val = coin::value<ArbQVE>(&arbqve_coin); 

        coin::merge(&mut pool.coin_y_reserve, arbqve_coin);
    }

    fun getValueofPool(pool: &LiquidityPool): (u64, u64) {
        let pool = borrow_global_mut<LiquidityPool>(@Qve);
        let x_reserve = coin::value(&pool.coin_x_reserve);
        let y_reserve = coin::value(&pool.coin_y_reserve);

        (x_reserve, y_reserve)
    }

    public entry fun addLiquidity_QVE(account: &signer, amount: u64) acquires LiquidityPool {
        let pool = borrow_global_mut<LiquidityPool>(@Qve);
        let x_reserve = coin::value(&pool.coin_x_reserve); // u64
        let y_reserve = coin::value(&pool.coin_y_reserve);

        // let one = 100000000;
        // assert!(x_reserve != 0, EZERO_TOKEN_IN_POOL);
        // if(x_reserve == 0) {
        //     putArbQVE(account, one*100);  // 100 initialize
        //     putQVE(account, one*100);  // 100 initialize
        //     return
        // };
        
        let return_amount = amount * y_reserve / x_reserve;
        // assert!(return_amount <= y_reserve, EINSUFFICIENT_BALANCE);
        // if(return_amount > y_reserve) {
        //     return
        // };

        let qve_coin = coin::withdraw<QVE>(account, amount);
        let arbqve_coin = coin::withdraw<ArbQVE>(account, return_amount);

        coin::merge(&mut pool.coin_x_reserve, qve_coin);
        coin::merge(&mut pool.coin_y_reserve, arbqve_coin);
    }

    public entry fun addLiquidity_ARB(account: &signer, amount: u64) acquires LiquidityPool {
        let pool = borrow_global_mut<LiquidityPool>(@Qve);
        let x_reserve = coin::value(&pool.coin_x_reserve);
        let y_reserve = coin::value(&pool.coin_y_reserve);

        // if(x_reserve < 100000000) {
        //     let one = 100000000;
        //     let qve_coin = coin::withdraw<QVE>(account, one);
        //     let arbqve_coin = coin::withdraw<ArbQVE>(account, one);
        //     // let qve_coin = coin::mint<QVE>(amount, &coin_cap.mint_cap_qv);
        //     // let arbqve_coin = coin::mint<ArbQVE>(amount, &coin_cap.mint_cap_arbqv);
        //     coin::merge(&mut pool.coin_x_reserve, qve_coin); 
        //     coin::merge(&mut pool.coin_y_reserve, arbqve_coin);
        // };

        let return_amount = amount * x_reserve / y_reserve;

        let qve_coin = coin::withdraw<QVE>(account, return_amount);
        let arbqve_coin = coin::withdraw<ArbQVE>(account, amount);

        coin::merge(&mut pool.coin_x_reserve, qve_coin);
        coin::merge(&mut pool.coin_y_reserve, arbqve_coin);
        
    }

    public entry fun swapQvetoArb(account: &signer, amount: u64) acquires LiquidityPool {
        let pool = borrow_global_mut<LiquidityPool>(@Qve);
        let x_reserve = coin::value(&pool.coin_x_reserve);
        let y_reserve = coin::value(&pool.coin_y_reserve);
        
        let k_value = x_reserve * y_reserve;

        let return_amount = y_reserve - (k_value / (amount + x_reserve));

        let qve_coin = coin::withdraw<QVE>(account, amount);
        coin::merge(&mut pool.coin_x_reserve, qve_coin); 

        let return_coin = coin::extract(&mut pool.coin_y_reserve, return_amount);
        coin::deposit(signer::address_of(account), return_coin);
    }

    public entry fun swapArbtoQve(account: &signer, amount: u64) acquires LiquidityPool {
        let pool = borrow_global_mut<LiquidityPool>(@Qve);
        let x_reserve = coin::value(&pool.coin_x_reserve);
        let y_reserve = coin::value(&pool.coin_y_reserve);
        
        let k_value = x_reserve * y_reserve;

        let return_amount = x_reserve - (k_value / (amount + y_reserve));

        let arb_coin = coin::withdraw<ArbQVE>(account, amount);
        coin::merge(&mut pool.coin_y_reserve, arb_coin); 

        let return_coin = coin::extract(&mut pool.coin_x_reserve, return_amount);
        coin::deposit(signer::address_of(account), return_coin);
    }
}
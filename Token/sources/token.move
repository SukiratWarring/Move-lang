module myAddress::Token{
    use std::signer;
    use std::debug::print;

    //ERROR CODES
    const NOT_OWNER:u64=0;
    const BALANCE_ALREADY_EXISTS:u64=1;
    const BALANCE_DOESNOT_EXISTS:u64=2;
    const BALANCE_IS_LESS:u64=3;
    const SENDING_AND_RECEIVEING_ARE_SAME:u64=4;

    struct Token has store{
        value:u64
    }
    struct Balance has key{
        tokens:Token
    }

    public fun assert_is_owner(addr: address) {
        assert!(addr == @myAddress, NOT_OWNER);
    }  

    public fun check_balance(add:address):bool{
        return exists<Balance>(add)
    }  
    #[view]
    public fun exact_balance(add:address):u64 acquires Balance{
        check_balance(add);
        borrow_global<Balance>(add).tokens.value
    }

    public entry fun mint(account:&signer,to:address,amount:u64)acquires Balance{
        let addr=signer::address_of(account);
        assert_is_owner(addr);
        deposit(to,amount);
    }

    public entry fun create_balance(account:&signer){
        let addr=signer::address_of(account);
        assert!(!check_balance(addr),BALANCE_ALREADY_EXISTS);
        move_to(account,Balance{tokens:Token{value:0}});

    }
    public fun transfer(from: &signer, to: address, amount: u64) acquires Balance{
        let from_addr=signer::address_of(from);
        assert!(check_balance(from_addr),BALANCE_DOESNOT_EXISTS);
        withdraw(from_addr,amount);
        assert!(from_addr!=to,SENDING_AND_RECEIVEING_ARE_SAME);
        deposit(to,amount);

    }

    fun withdraw(from_addr:address,amount:u64) acquires Balance{
        assert!(borrow_global<Balance>(from_addr).tokens.value>=amount,BALANCE_IS_LESS);
        let curr=&mut borrow_global_mut<Balance>(from_addr).tokens.value;
        *curr=*curr-amount;
    }

    fun deposit(to: address, amount: u64) acquires Balance{
        let curr=&mut borrow_global_mut<Balance>(to).tokens.value;
        *curr=*curr+amount;
    }    

    public fun burn(from:&signer,amount:u64)acquires Balance{
        let from_addr=signer::address_of(from);
        assert!(exact_balance(from_addr)>=amount,BALANCE_IS_LESS);
        withdraw(from_addr,amount);

    }


}
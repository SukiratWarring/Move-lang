module myAddress::Token{
    use std::signer;
    use std::debug::print;

    //ERROR CODES
    const BALANCE_ALREADY_EXISTS:u64=1;
    const BALANCE_DOESNOT_EXISTS:u64=2;
    const BALANCE_IS_LESS:u64=3;
    const SENDING_AND_RECEIVEING_ARE_SAME:u64=4;

    struct Token has store,drop {
        value:u64
    }
    struct Balance has key,drop{
        tokens:Token
    }

    public fun check_balance(add:address):bool{
        return exists<Balance>(add)
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

    public fun withdraw(from_addr:address,amount:u64) acquires Balance{
        assert!(borrow_global<Balance>(from_addr).tokens.value>=amount,BALANCE_IS_LESS);
        let curr=&mut borrow_global_mut<Balance>(from_addr).tokens.value;
        *curr=*curr-amount;
    }

    public fun deposit(to: address, amount: u64) acquires Balance{
        let curr=&mut borrow_global_mut<Balance>(to).tokens.value;
        *curr=*curr+amount;
    }    

    public fun burn(account:&signer,amount:u64)acquires Balance{
        let to_addr=signer::address_of(account);
        assert!(borrow_global<Balance>(to_addr).tokens.value>=amount,BALANCE_IS_LESS);
        let curr=&borrow_global<Balance>(to_addr).tokens.value;
        // print(&curr);
        if(amount==*curr){
            move_from<Balance>(to_addr);
        }else{
            withdraw(to_addr,amount);
        }

    }

}
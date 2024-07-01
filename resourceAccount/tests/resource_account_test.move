#[test_only]
module myAddress::res_acc_tests{
    use std::signer;
    use std::vector;
    use myAddress::Resource_account::{Self,MintProofChallenge};
    use aptos_token::token::{Self,TokenDataId};
    use aptos_framework::timestamp;

    use aptos_framework::account::{Self};
    use aptos_framework::account::create_account_for_test;
    use aptos_framework::resource_account;
    use std::debug::print;
    use aptos_std::ed25519;
    


    public entry fun setup_test_environment(myAddress: &signer,origin_account:signer,nft_receiver:&signer,admin_pk_verification:&ed25519::ValidatedPublicKey,aptos_framework:signer) {
         // set up global time for testing purpose
        timestamp::set_time_has_started_for_testing(&aptos_framework);
        // timestamp::update_global_time_for_test_secs(timestamp);
        create_account_for_test(signer::address_of(&origin_account));
        // create a resource account from the origin account, mocking the module publishing process
        resource_account::create_resource_account(&origin_account, vector::empty<u8>(), vector::empty<u8>());
        create_account_for_test(signer::address_of(nft_receiver));
        let auth_acc=create_account_for_test(@auth_acc);
        Resource_account::init_test(myAddress);
        let p=Resource_account::get_module_data_token_id();
        print<TokenDataId>(&p);
        let pk_bytes=ed25519::validated_public_key_to_bytes(admin_pk_verification);
        Resource_account::set_public_key(&auth_acc,pk_bytes);
        
    }    
    

    #[test(
        myAddress = @0xc3bb8488ab1a5815a9d543d7e41b0e0df46a7396f89b22821f07a4362f75ddc5,
        origin_acc = @0xcafe,
        nft_rec_acc = @0x123,
        aptos_framework=@aptos_framework,
        auth_acc= @auth_acc,
    )]
    public entry fun test_setup_and_mint(myAddress:signer,origin_acc:signer,nft_rec_acc:signer,aptos_framework:signer
    ,auth_acc:signer
    ){
        let (admin_sk, admin_pk) = ed25519::generate_keys();

        setup_test_environment(&myAddress,origin_acc,&nft_rec_acc,&admin_pk,aptos_framework);
        let token_id=Resource_account::get_tokenId();
        //Enable Mint
        Resource_account::enable_mint(&auth_acc);
        //Creating proof
        let proof=Resource_account::create_proof(&nft_rec_acc);
        //   Signing it with admin
        let signature=ed25519::sign_struct(&admin_sk, proof);

        // minting nft
        Resource_account::mint(&nft_rec_acc,ed25519::signature_to_bytes(&signature));

        let amt=token::balance_of(signer::address_of(&nft_rec_acc), token_id);
        print<u64>(&amt);
        assert!(amt==1,0);

    }
}
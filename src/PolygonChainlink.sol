// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { AggregatorV3Interface } from "./interfaces/AggregatorV3Interface.sol";

library PolygonChainlink {

    error PriceFeedNotFound(address from, address to);

    error AggregratorNotFound(AggregatorV3Interface aggregator);

    address constant ADDRESS_wBTC = 0x1BFD67037B42Cf73acF2047067bd4F2C47D9BfD6;
    address constant ADDRESS_wETH = 0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619;
    address constant ADDRESS_USDC = 0x3c499c542cEF5E3811e1192ce70d8cC03d5c3359;
    address constant ADDRESS_USDT = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F;
    address constant ADDRESS_SHIB = 0x6f8a06447Ff6FcF75d803135a7de15CE88C1d4ec;
    address constant ADDRESS_APE = 0xB7b31a6BC18e48888545CE79e83E06003bE70930;
    address constant ADDRESS_PAXG = 0x553d3D295e0f695B9228246232eDF400ed3560B5;
    address constant ADDRESS_1INCH = 0x9c2C5fd7b07E95EE044DDeba0E97a665F142394f;
    address constant ADDRESS_AAVE = 0xf329e36C7bF6E5E86ce2150875a84Ce77f477375;
    address constant ADDRESS_AVAX = 0x2C89bbc92BD86F8075d1DEcc58C7F4E0107f286b;
    //address constant ADDRESS_SOL = 0xD31a59c85aE9D8edEFeC411D448f90841571b89c;
    //address constant ADDRESS_ARB = 0xB50721BCf8d664c30412Cfbc6cf7a15145234ad1;
    address constant ADDRESS_CRV = 0x172370d5Cd63279eFa6d502DAB29171933a610AF;
    address constant ADDRESS_COMP = 0x8505b9d2254A7Ae468c0E9dd10Ccea3A837aef5c;
    address constant ADDRESS_MATIC = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
    address constant ADDRESS_UNI = 0xb33EaAd8d922B1083446DC23f610c2567fB5180f;
    address constant ADDRESS_SUSHI = 0x0b3F868E0BE5597D5DB7fEB59E1CADBb0fdDa50a; 

    //IERC20 constant USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);

    AggregatorV3Interface constant PolygonUSDCtoETH = AggregatorV3Interface(0xefb7e6be8356cCc6827799B6A7348eE674A80EaE); //ok
    AggregatorV3Interface constant PolygonETHtoUSD = AggregatorV3Interface(0xF9680D99D6C9589e2a93a78A04A279e509205945); //ok
    AggregatorV3Interface constant PolygonBTCtoUSD = AggregatorV3Interface(0xc907E116054Ad103354f2D350FD2514433D57F6f); //ok (I can not see if wBTC deppeg, so I will not use this one)
    //AggregatorV3Interface constant PolygonWBTCtoBTC = AggregatorV3Interface(0xfdFD9C85aD200c506Cf9e21F1FD8dd01932FBB23);
    AggregatorV3Interface constant PolygonWBTCtoUSD = AggregatorV3Interface(0xDE31F8bFBD8c84b5360CFACCa3539B938dd78ae6); //ok 
    //AggregatorV3Interface constant PolygonETHtoBTC = AggregatorV3Interface(0xAc559F25B1619171CbC396a50854A3240b6A4e99);
    AggregatorV3Interface constant PolygonBTCtoETH = AggregatorV3Interface(0x19b0F0833C78c0848109E3842D34d2fDF2cA69BA); //ok (I can not see if wBTC deppeg, so I will not use this one)
    AggregatorV3Interface constant PolygonUSDCtoUSD = AggregatorV3Interface(0xfE4A8cc5b5B2366C1B58Bea3858e81843581b2F7); //ok
    //AggregatorV3Interface constant PolygonSHIBtoETH = AggregatorV3Interface(0x8dD1CD88F43aF196ae478e91b9F5E4Ac69A97C61);
    AggregatorV3Interface constant PolygonSHIBtoUSD = AggregatorV3Interface(0x3710abeb1A0Fc7C2EC59C26c8DAA7a448ff6125A); //ok
    //AggregatorV3Interface constant PolygonPAXGtoETH = AggregatorV3Interface(0x9B97304EA12EFed0FAd976FBeCAad46016bf269e);
    AggregatorV3Interface constant PolygonPAXGtoUSD = AggregatorV3Interface(0x0f6914d8e7e1214CDb3A4C6fbf729b75C69DF608); //ok
    AggregatorV3Interface constant PolygonMATICtoUSD = AggregatorV3Interface(0xAB594600376Ec9fD91F8e885dADF0CE036862dE0); //ok
    AggregatorV3Interface constant PolygonSOLtoUSD = AggregatorV3Interface(0x10C8264C0935b3B9870013e057f330Ff3e9C56dC); //ok
    AggregatorV3Interface constant PolygonADAtoUSD = AggregatorV3Interface(0x882554df528115a743c4537828DA8D5B58e52544); //ok
    AggregatorV3Interface constant PolygonAVAXtoUSD = AggregatorV3Interface(0xe01eA2fbd8D76ee323FbEd03eB9a8625EC981A10); //ok
    AggregatorV3Interface constant PolygonAAVEtoUSD = AggregatorV3Interface(0x72484B12719E23115761D5DA1646945632979bB6); //ok
    AggregatorV3Interface constant PolygonAAVEtoETH = AggregatorV3Interface(0xbE23a3AA13038CfC28aFd0ECe4FdE379fE7fBfc4); //ok
    //AggregatorV3Interface constant PolygonARBtoUSD = AggregatorV3Interface(0x31697852a68433DbCc2Ff612c516d69E3D9bd08F);
    AggregatorV3Interface constant PolygonAPEtoUSD = AggregatorV3Interface(0x2Ac3F3Bfac8fC9094BC3f0F9041a51375235B992); //ok
    //AggregatorV3Interface constant PolygonAPEtoETH = AggregatorV3Interface(0xc7de7f4d4C9c991fF62a07D18b3E31e349833A18);
    AggregatorV3Interface constant PolygonCOMPtoUSD = AggregatorV3Interface(0x2A8758b7257102461BC958279054e372C2b1bDE6); //ok
    //AggregatorV3Interface constant PolygonCOMPtoETH = AggregatorV3Interface(0x1B39Ee86Ec5979ba5C322b826B3ECb8C79991699);
    AggregatorV3Interface constant Polygon1INCHtoUSD = AggregatorV3Interface(0x443C5116CdF663Eb387e72C688D276e702135C87); //ok
    //AggregatorV3Interface constant Polygon1INCHtoETH = AggregatorV3Interface(0x72AFAECF99C9d9C8215fF44C77B94B99C28741e8);
    AggregatorV3Interface constant PolygonCRVtoUSD = AggregatorV3Interface(0x336584C8E6Dc19637A5b36206B1c79923111b405); //ok
    AggregatorV3Interface constant PolygonCRVtoETH = AggregatorV3Interface(0x1CF68C76803c9A415bE301f50E82e44c64B7F1D4); //ok
    AggregatorV3Interface constant PolygonUNItoUSD = AggregatorV3Interface(0xdf0Fb4e4F928d2dCB76f438575fDD8682386e13C); //ok
    AggregatorV3Interface constant PolygonUNItoETH = AggregatorV3Interface(0x162d8c5bF15eB6BEe003a1ffc4049C92114bc931); //ok
    AggregatorV3Interface constant PolygonSUSHItoUSD = AggregatorV3Interface(0x49B0c695039243BBfEb8EcD054EB70061fd54aa0); //ok
    AggregatorV3Interface constant PolygonSUSHItoETH = AggregatorV3Interface(0x17414Eb5159A082e8d41D243C1601c2944401431); //ok

    function getPriceFeedAddress(address from, address to) public pure returns(AggregatorV3Interface) {
        if(to == ADDRESS_USDC){

            if(from == ADDRESS_wBTC) return PolygonWBTCtoUSD;

            else if(from == ADDRESS_wETH) return PolygonETHtoUSD;

            else if(from == ADDRESS_1INCH) return Polygon1INCHtoUSD;

            else if(from == ADDRESS_USDC) return PolygonUSDCtoUSD;

            else if(from == ADDRESS_SHIB) return PolygonSHIBtoUSD;
            
            else if(from == ADDRESS_PAXG) return PolygonPAXGtoUSD;

            else if(from == ADDRESS_MATIC) return PolygonMATICtoUSD;

            else if(from == ADDRESS_APE) return PolygonAPEtoUSD;

            //else if(from == ADDRESS_ARB) return PolygonARBtoUSD;

            else if(from == ADDRESS_AVAX) return PolygonAVAXtoUSD;

            else if(from == ADDRESS_AAVE) return PolygonAAVEtoUSD;

            //else if(from == ADDRESS_SOL) return PolygonSOLtoUSD;

            else if(from == ADDRESS_CRV) return PolygonCRVtoUSD;

            else if(from == ADDRESS_COMP) return PolygonCOMPtoUSD;

            else if(from == ADDRESS_UNI) return PolygonUNItoUSD;

            else if(from == ADDRESS_SUSHI) return PolygonSUSHItoUSD;

            else revert PriceFeedNotFound(from, to);
        }

        else if(to == ADDRESS_wETH){

            //if(from == ADDRESS_wBTC) return PolygonBTCtoETH;

            //else if(from == ADDRESS_1INCH) return Polygon1INCHtoETH;

            //else if(from == ADDRESS_APE) return PolygonAPEtoETH;

            //else if(from == ADDRESS_SHIB) return PolygonSHIBtoETH;

            //else if(from == ADDRESS_PAXG) return PolygonPAXGtoETH;

            if(from == ADDRESS_AAVE) return PolygonAAVEtoETH;

            //else if(from == ADDRESS_SOL) return PolygonSOLtoETH;

            else if(from == ADDRESS_CRV) return PolygonCRVtoETH;

            //else if(from == ADDRESS_COMP) return PolygonCOMPtoETH;

            else if(from == ADDRESS_UNI) return PolygonUNItoETH;

            else if(from == ADDRESS_SUSHI) return PolygonSUSHItoETH;

            //else if(from == ADDRESS_MATIC) return PolygonMATICtoETH;

            else revert PriceFeedNotFound(from, to);
        }

        /* else if(to == ADDRESS_wBTC) {

            if() return

            //if(from == ADDRESS_wBTC) return PolygonWBTCtoBTC;

            //else if(from == ADDRESS_wETH) return PolygonETHtoBTC;

            else revert PriceFeedNotFound(from, to);
        } */

        else revert PriceFeedNotFound(from, to);
    }

    function getTokensFromPriceFeed(AggregatorV3Interface priceFeed) public pure returns(address from, address to) {
        // USDC destination pairs
        if(priceFeed == PolygonWBTCtoUSD) return (ADDRESS_wBTC, ADDRESS_USDC);
        if(priceFeed == PolygonETHtoUSD) return (ADDRESS_wETH, ADDRESS_USDC);
        if(priceFeed == Polygon1INCHtoUSD) return (ADDRESS_1INCH, ADDRESS_USDC);
        if(priceFeed == PolygonUSDCtoUSD) return (ADDRESS_USDC, ADDRESS_USDC);
        if(priceFeed == PolygonSHIBtoUSD) return (ADDRESS_SHIB, ADDRESS_USDC);
        if(priceFeed == PolygonPAXGtoUSD) return (ADDRESS_PAXG, ADDRESS_USDC);
        if(priceFeed == PolygonMATICtoUSD) return (ADDRESS_MATIC, ADDRESS_USDC);
        if(priceFeed == PolygonAPEtoUSD) return (ADDRESS_APE, ADDRESS_USDC);
        // if(priceFeed == PolygonARBtoUSD) return (ADDRESS_ARB, ADDRESS_USDC);
        if(priceFeed == PolygonAVAXtoUSD) return (ADDRESS_AVAX, ADDRESS_USDC);
        if(priceFeed == PolygonAAVEtoUSD) return (ADDRESS_AAVE, ADDRESS_USDC);
        // if(priceFeed == PolygonSOLtoUSD) return (ADDRESS_SOL, ADDRESS_USDC);
        if(priceFeed == PolygonCRVtoUSD) return (ADDRESS_CRV, ADDRESS_USDC);
        if(priceFeed == PolygonCOMPtoUSD) return (ADDRESS_COMP, ADDRESS_USDC);
        if(priceFeed == PolygonUNItoUSD) return (ADDRESS_UNI, ADDRESS_USDC);
        if(priceFeed == PolygonSUSHItoUSD) return (ADDRESS_SUSHI, ADDRESS_USDC);

        // wETH destination pairs
        // if(priceFeed == PolygonBTCtoETH) return (ADDRESS_wBTC, ADDRESS_wETH);
        // if(priceFeed == Polygon1INCHtoETH) return (ADDRESS_1INCH, ADDRESS_wETH);
        // if(priceFeed == PolygonAPEtoETH) return (ADDRESS_APE, ADDRESS_wETH);
        // if(priceFeed == PolygonSHIBtoETH) return (ADDRESS_SHIB, ADDRESS_wETH);
        // if(priceFeed == PolygonPAXGtoETH) return (ADDRESS_PAXG, ADDRESS_wETH);
        if(priceFeed == PolygonAAVEtoETH) return (ADDRESS_AAVE, ADDRESS_wETH);
        // if(priceFeed == PolygonSOLtoETH) return (ADDRESS_SOL, ADDRESS_wETH);
        if(priceFeed == PolygonCRVtoETH) return (ADDRESS_CRV, ADDRESS_wETH);
        // if(priceFeed == PolygonCOMPtoETH) return (ADDRESS_COMP, ADDRESS_wETH);
        if(priceFeed == PolygonUNItoETH) return (ADDRESS_UNI, ADDRESS_wETH);
        if(priceFeed == PolygonSUSHItoETH) return (ADDRESS_SUSHI, ADDRESS_wETH);
        // if(priceFeed == PolygonMATICtoETH) return (ADDRESS_MATIC, ADDRESS_wETH);

        // wBTC destination pairs (commented out in original)
        // if(priceFeed == PolygonWBTCtoBTC) return (ADDRESS_wBTC, ADDRESS_wBTC);
        // if(priceFeed == PolygonETHtoBTC) return (ADDRESS_wETH, ADDRESS_wBTC);

        revert PriceFeedNotFound(address(priceFeed), address(0));
    }

    function getHeartbeat(AggregatorV3Interface aggregator) public pure returns(uint32 heartbeat) {

        if(
            aggregator == PolygonETHtoUSD ||
            aggregator == PolygonBTCtoUSD ||
            aggregator == PolygonUSDCtoUSD ||
            aggregator == PolygonAAVEtoUSD ||
            aggregator == PolygonCOMPtoUSD ||
            aggregator == PolygonMATICtoUSD || 
            aggregator == PolygonUNItoUSD ||
            aggregator == Polygon1INCHtoUSD ||
            aggregator == PolygonSOLtoUSD
        )
        return heartbeat = 27;

        else if(
            aggregator == PolygonCRVtoUSD ||
            aggregator == PolygonWBTCtoUSD
        )
        return heartbeat = 300;

        /* else if(
            
            
            
            
             //||
            //aggregator == PolygonETHtoBTC
            ) 
            return heartbeat = 3600; */

        else if(
            
            aggregator == PolygonAPEtoUSD ||
            //aggregator == PolygonARBtoUSD ||
            aggregator == PolygonAVAXtoUSD ||
            //aggregator == Polygon1INCHtoETH ||
            //aggregator == PolygonAPEtoETH ||
            //aggregator == PolygonSHIBtoETH ||
            //aggregator == PolygonPAXGtoETH ||
            aggregator == PolygonAAVEtoETH ||
            aggregator == PolygonCRVtoETH ||
            //aggregator == PolygonCOMPtoETH ||
            aggregator == PolygonUNItoETH ||
            aggregator == PolygonSUSHItoUSD ||
            aggregator == PolygonSUSHItoETH //||
            //aggregator == PolygonWBTCtoBTC
            ) return heartbeat = 86400;
    }
    
}
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import { Script } from "forge-std/Script.sol";
import { ERC1967Proxy } from "openzeppelin/proxy/ERC1967/ERC1967Proxy.sol";

import { SoundFeeRegistry } from "@core/SoundFeeRegistry.sol";
import { SoundEditionV1 } from "@core/SoundEditionV1.sol";
import { SoundCreatorV1 } from "@core/SoundCreatorV1.sol";
import { IMetadataModule } from "@core/interfaces/IMetadataModule.sol";
import { GoldenEggMetadata } from "@modules/GoldenEggMetadata.sol";
import { FixedPriceSignatureMinter } from "@modules/FixedPriceSignatureMinter.sol";
import { MerkleDropMinter } from "@modules/MerkleDropMinter.sol";
import { RangeEditionMinter } from "@modules/RangeEditionMinter.sol";
import { EditionMaxMinter } from "@modules/EditionMaxMinter.sol";
import { RedemptionMinter } from "@modules/RedemptionMinter.sol";

contract Deploy is Script {

    string constant NAME = "DEMO DROP";
    string constant SYMBOL = "DEMO";
    string constant BASE_URI = "https://example.com/metadata/";
    string constant CONTRACT_URI = "https://example.com/storefront/";
    uint16 constant ROYALTY_BPS = 100;
    uint8 constant FLAGS = 0;

    uint256 internal _salt1 = 1;
    uint256 internal _salt2 = 2;
    
    
    
    address soundCreatorAddress = 0xAef3e8c8723D9c31863BE8dE54dF2668Ef7c4B89;
    address editionMaxMinterAddress = 0x5E5d50Ea70c9a1B6ED64506F121b094156B8Fd20;
    
    uint16 private PLATFORM_FEE_BPS = uint16(vm.envUint("PLATFORM_FEE_BPS"));
    address private OWNER = vm.envAddress("OWNER");


    function run() external {
        vm.startBroadcast();


        // Deploy minter modules
        SoundFeeRegistry soundFeeRegistry = new SoundFeeRegistry(OWNER, PLATFORM_FEE_BPS);
        RedemptionMinter redemptionMinter = new RedemptionMinter(soundFeeRegistry);

        // Deploy the SoundCreator
        SoundCreatorV1 soundCreator = SoundCreatorV1(soundCreatorAddress);
        EditionMaxMinter editionMaxMinter = EditionMaxMinter(editionMaxMinterAddress);

        bytes memory initData1 = abi.encodeWithSelector(
            SoundEditionV1.initialize.selector,
            NAME,
            SYMBOL,
            address(0),
            BASE_URI,
            CONTRACT_URI,
            OWNER,
            ROYALTY_BPS,
            0,
            888,
            block.timestamp + 30 days,
            FLAGS
        );

        bytes memory initData2 = abi.encodeWithSelector(
            SoundEditionV1.initialize.selector,
            "Secret Drop",
            "SECRET",
            address(0),
            BASE_URI,
            CONTRACT_URI,
            OWNER,
            ROYALTY_BPS,
            0,
            100,
            block.timestamp + 30 days,
            FLAGS
        );


        address[] memory contracts;
        bytes[] memory data;

        (address songEditionAddress, ) = soundCreator.createSoundAndMints(bytes32(_salt1), initData1, contracts, data);
        SoundEditionV1 songEdition = SoundEditionV1(songEditionAddress);
        songEdition.grantRoles(editionMaxMinterAddress, songEdition.MINTER_ROLE());

        (address secretEditionAddress, ) = soundCreator.createSoundAndMints(bytes32(_salt2), initData2, contracts, data);
        SoundEditionV1 secretEdition = SoundEditionV1(secretEditionAddress);
        secretEdition.grantRoles(address(redemptionMinter), secretEdition.MINTER_ROLE());
        
        
        _helper(editionMaxMinter, redemptionMinter, songEditionAddress, secretEditionAddress);

        vm.stopBroadcast();
    }
    
    function _helper(EditionMaxMinter editionMaxMinter, RedemptionMinter redemptionMinter, address songEditionAddress, address secretEditionAddress ) internal {
        
        uint32 start = uint32(block.timestamp);
        uint32 end = uint32(block.timestamp + 30 days);

        editionMaxMinter.createEditionMint(songEditionAddress, 0.01 ether, start, end, 0, 50);
        redemptionMinter.createRedemptionMint(songEditionAddress, secretEditionAddress, 4, start, end, 5);
    }
}

// Predict address of new implementation
// Create metadata module using predicted address
// Create new edition implementation with flags and module address
// Deploy mint contract
// Grant mint contract mint permissions on edition

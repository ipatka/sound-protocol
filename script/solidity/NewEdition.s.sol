// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import { Script } from "forge-std/Script.sol";
import { ERC1967Proxy } from "openzeppelin/proxy/ERC1967/ERC1967Proxy.sol";

import { SoundFeeRegistry } from "@core/SoundFeeRegistry.sol";
import { SoundEditionV1 } from "@core/SoundEditionV1.sol";
import { SoundEditionV1a } from "@core/SoundEditionV1a.sol";
import { SoundCreatorV1 } from "@core/SoundCreatorV1.sol";
import { IMetadataModule } from "@core/interfaces/IMetadataModule.sol";
import { GoldenEggMetadata } from "@modules/GoldenEggMetadata.sol";
import { FixedPriceSignatureMinter } from "@modules/FixedPriceSignatureMinter.sol";
import { MerkleDropMinter } from "@modules/MerkleDropMinter.sol";
import { RangeEditionMinter } from "@modules/RangeEditionMinter.sol";
import { EditionMaxMinter } from "@modules/EditionMaxMinter.sol";
import { RarityShuffleMetadata } from "@modules/RarityShuffleMetadata.sol";

contract NewEdition is Script {
    address private OWNER = vm.envAddress("OWNER");
    address private SOUND_CREATOR = vm.envAddress("SOUND_CREATOR");
    address private EDITION_MAX_MINTER = vm.envAddress("EDITION_MAX_MINTER");
    address private MERKLE_MINTER = vm.envAddress("MERKLE_MINTER");
    address private RANGE_MINTER = vm.envAddress("RANGE_MINTER");
    uint8 public constant MINT_RANDOMNESS_ENABLED_FLAG = 1 << 1;
    uint8 public constant METADATA_TRIGGER_ENABLED_FLAG = 1 << 2;


    bytes32 public root = 0x300553b4ba80acf94444e931c71e13c74335ca9a131aaba39339ef7aa8cc8ca3;


    uint256 internal _salt = 2;

      uint256[] _ranges;

    string constant NAME = "DEMO DROP";
    string constant SYMBOL = "DEMO";
    string constant BASE_URI = "https://example.com/metadata/";
    string constant CONTRACT_URI = "https://example.com/storefront/";
    uint16 constant ROYALTY_BPS = 100;
    uint8 constant FLAGS = MINT_RANDOMNESS_ENABLED_FLAG | METADATA_TRIGGER_ENABLED_FLAG;

    function run() external {
        vm.startBroadcast();

        _ranges.push(0);
        _ranges.push(259);
        _ranges.push(409);
        _ranges.push(534);
        _ranges.push(634);
        _ranges.push(709);
        _ranges.push(759);
        _ranges.push(799);
        _ranges.push(829);
        _ranges.push(849);
        _ranges.push(865);
        _ranges.push(877);
        _ranges.push(885);

        SoundCreatorV1 soundCreator = SoundCreatorV1(SOUND_CREATOR);
        EditionMaxMinter minter = EditionMaxMinter(EDITION_MAX_MINTER);
        MerkleDropMinter merkleMinter = MerkleDropMinter(MERKLE_MINTER);
        RangeEditionMinter rangeMinter = RangeEditionMinter(RANGE_MINTER);
        
        (address predictedSoundAddress,) = soundCreator.soundEditionAddress(OWNER, bytes32(_salt));


        // RarityShuffleMetadata module = new RarityShuffleMetadata(
        //   predictedSoundAddress,
        //   888,
        //   13,
        //   _ranges
        // );

        // bytes memory initData = abi.encodeWithSelector(
        //     SoundEditionV1.initialize.selector,
        //     NAME,
        //     SYMBOL,
        //     address(module),
        //     BASE_URI,
        //     CONTRACT_URI,
        //     OWNER,
        //     ROYALTY_BPS,
        //     0,
        //     888,
        //     block.timestamp + 30 days,
        //     FLAGS
        // );

        address[] memory contracts;
        bytes[] memory data;

        // soundCreator.createSoundAndMints(bytes32(_salt), initData, contracts, data);
        (address addr, ) = soundCreator.soundEditionAddress(OWNER, bytes32(_salt));
        SoundEditionV1a edition = SoundEditionV1a(addr);
        
        // edition.grantRoles(address(minter), edition.MINTER_ROLE());
        edition.grantRoles(address(merkleMinter), edition.MINTER_ROLE());
        // edition.grantRoles(address(rangeMinter), edition.MINTER_ROLE());
        
        // minter.createEditionMint(
        //   addr,
        //   0.0008 ether,
        //   uint32(block.timestamp),
        //   uint32(block.timestamp + 30 days),
        //   0,
        //   100
        // );
        
        // setUpMerkleTree();
        
        
        merkleMinter.createEditionMint(
          addr,
          root,
          0.0008 ether,
          uint32(block.timestamp),
          uint32(block.timestamp + 30 days),
          0,
          888,
          100
        );
        
        // rangeMinter.createEditionMint(
        //   addr,
        //   0.0008 ether,
        //   uint32(block.timestamp),
        //   uint32(block.timestamp + 29 days),
        //   uint32(block.timestamp + 30 days),
        //   0,
        //   888,
        //   888,
        //   100
        // );


        vm.stopBroadcast();
    }
}

// Predict address of new implementation
// Create metadata module using predicted address
// Create new edition implementation with flags and module address
// Deploy mint contract
// Grant mint contract mint permissions on edition
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
import { RedemptionMinter } from "@modules/RedemptionMinter.sol";
import { RarityShuffleMetadata } from "@modules/RarityShuffleMetadata.sol";

contract NewEdition is Script {
    address private OWNER = vm.envAddress("OWNER");
    address private SOUND_CREATOR_V1A = vm.envAddress("SOUND_CREATOR_V1A");
    address private SOUND_CREATOR = vm.envAddress("SOUND_CREATOR");
    address private EDITION_MAX_MINTER = vm.envAddress("EDITION_MAX_MINTER");
    address private MERKLE_MINTER = vm.envAddress("MERKLE_MINTER");
    address private REDEMPTION_MINTER = vm.envAddress("REDEMPTION_MINTER");
    address private RANGE_MINTER = vm.envAddress("RANGE_MINTER");
    uint8 public constant METADATA_TRIGGER_ENABLED_FLAG = 1 << 2;


    bytes32 public root = 0xcf8a027abc2f84431e66330dbc0a2b3e906b2b37712e35a0b7f47bdaf76940d5;


    uint256 internal _salt = 9;

    uint256[] _ranges;

    string constant NAME = "DEMO DROP";
    string constant SYMBOL = "DEMO";
    string constant NAME_HIDDEN = "DEMO DROP HIDDEN";
    string constant SYMBOL_HIDDEN = "HIDDEN";
    string constant BASE_URI = "ipfs://QmaL6JELNbTgUo3yzhKCqxsEtYDk3PLhHrWvg2oCpsFTrZ/";
    string constant BASE_URI_SECRET = "ipfs://QmcMWMK9LheENLHK6pqSDxJgYjenMGtos4ngjouqxP6JKd/";
    string constant CONTRACT_URI = "https://example.com/storefront/";
    uint16 constant ROYALTY_BPS = 100;
    uint8 constant FLAGS = METADATA_TRIGGER_ENABLED_FLAG;
    uint8 constant HIDDEN_FLAGS = 0;

        uint32 start = uint32(block.timestamp);
        uint32 end = uint32(block.timestamp + 30 days);

    function run() external {
        vm.startBroadcast();

        _ranges.push(0);
        _ranges.push(60);
        _ranges.push(120);
        _ranges.push(180);
        _ranges.push(220);
        _ranges.push(260);
        _ranges.push(300);
        _ranges.push(330);
        _ranges.push(360);
        _ranges.push(390);
        _ranges.push(416);
        _ranges.push(432);
        _ranges.push(440);

        SoundCreatorV1 soundCreatorv1a = SoundCreatorV1(SOUND_CREATOR_V1A);
        SoundCreatorV1 soundCreator = SoundCreatorV1(SOUND_CREATOR);
        MerkleDropMinter merkleMinter = MerkleDropMinter(MERKLE_MINTER);
        RedemptionMinter redemptionMinter = RedemptionMinter(REDEMPTION_MINTER);
        
        (address predictedSoundAddress,) = soundCreatorv1a.soundEditionAddress(OWNER, bytes32(_salt));
        // (address predictedHiddenAddress,) = soundCreator.soundEditionAddress(OWNER, bytes32(_salt));


        RarityShuffleMetadata module = new RarityShuffleMetadata(
          predictedSoundAddress,
          444,
          13,
          _ranges
        );

        bytes memory initData = abi.encodeWithSelector(
            SoundEditionV1.initialize.selector,
            NAME,
            SYMBOL,
            address(module),
            BASE_URI,
            CONTRACT_URI,
            OWNER,
            ROYALTY_BPS,
            0,
            444,
            block.timestamp + 30 days,
            FLAGS
        );

        bytes memory hiddenInitData = abi.encodeWithSelector(
            SoundEditionV1.initialize.selector,
            NAME_HIDDEN,
            SYMBOL_HIDDEN,
            address(0),
            BASE_URI_SECRET,
            CONTRACT_URI,
            OWNER,
            ROYALTY_BPS,
            0,
            111,
            block.timestamp + 30 days,
            HIDDEN_FLAGS
        );

        address[] memory contracts;
        bytes[] memory data;

        soundCreatorv1a.createSoundAndMints(bytes32(_salt), initData, contracts, data);
        soundCreator.createSoundAndMints(bytes32(_salt), hiddenInitData, contracts, data);

        (address addr, ) = soundCreatorv1a.soundEditionAddress(OWNER, bytes32(_salt));
        SoundEditionV1a edition = SoundEditionV1a(addr);

        (address hiddenAddr, ) = soundCreator.soundEditionAddress(OWNER, bytes32(_salt));
        SoundEditionV1 hiddenEdition = SoundEditionV1(hiddenAddr);
        
        // edition.grantRoles(address(minter), edition.MINTER_ROLE());
        edition.grantRoles(address(merkleMinter), edition.MINTER_ROLE());
        hiddenEdition.grantRoles(address(redemptionMinter), hiddenEdition.MINTER_ROLE());
        
        merkleMinter.createEditionMint(
          addr,
          root,
          0.0008 ether,
          start,
          end,
          0,
          444,
          100
        );

        redemptionMinter.createRedemptionMint(addr, hiddenAddr, 4, start, end, 5);
        

        vm.stopBroadcast();
    }
}

// Predict address of new implementation
// Create metadata module using predicted address
// Create new edition implementation with flags and module address
// Deploy mint contract
// Grant mint contract mint permissions on edition
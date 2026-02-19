"""
Test suite for esp_wifi_tx module
Run these tests on your ESP32-S3 after flashing the firmware
"""

import esp_wifi_tx
import network
import time

# Test results storage
test_results = {
    'passed': 0,
    'failed': 0,
    'errors': []
}

def test_module_import():
    """Test 1: Module can be imported"""
    try:
        assert esp_wifi_tx is not None
        print("✓ Test 1: Module import - PASSED")
        return True
    except Exception as e:
        print(f"✗ Test 1: Module import - FAILED: {e}")
        test_results['errors'].append(str(e))
        return False

def test_constants_exist():
    """Test 2: Required constants exist"""
    try:
        assert hasattr(esp_wifi_tx, 'WIFI_IF_STA')
        assert hasattr(esp_wifi_tx, 'WIFI_IF_AP')
        assert esp_wifi_tx.WIFI_IF_STA == 0
        assert esp_wifi_tx.WIFI_IF_AP == 1
        print("✓ Test 2: Constants - PASSED")
        return True
    except Exception as e:
        print(f"✗ Test 2: Constants - FAILED: {e}")
        test_results['errors'].append(str(e))
        return False

def test_function_exists():
    """Test 3: wifi_80211_tx function exists"""
    try:
        assert hasattr(esp_wifi_tx, 'wifi_80211_tx')
        assert callable(esp_wifi_tx.wifi_80211_tx)
        print("✓ Test 3: Function exists - PASSED")
        return True
    except Exception as e:
        print(f"✗ Test 3: Function exists - FAILED: {e}")
        test_results['errors'].append(str(e))
        return False

def test_wifi_initialization():
    """Test 4: WiFi can be initialized"""
    try:
        sta = network.WLAN(network.STA_IF)
        sta.active(True)
        time.sleep(0.5)
        assert sta.active() == True
        print("✓ Test 4: WiFi initialization - PASSED")
        return True
    except Exception as e:
        print(f"✗ Test 4: WiFi initialization - FAILED: {e}")
        test_results['errors'].append(str(e))
        return False

def test_invalid_interface():
    """Test 5: Invalid interface handling"""
    try:
        # Initialize WiFi first
        sta = network.WLAN(network.STA_IF)
        sta.active(True)
        time.sleep(0.5)
        
        # Try invalid interface
        frame = bytes([0x80, 0x00, 0x00, 0x00] + [0xFF] * 100)
        ret = esp_wifi_tx.wifi_80211_tx(99, frame)  # Invalid interface
        
        # Should return error (negative)
        if ret != 0:
            print(f"✓ Test 5: Invalid interface - PASSED (returned {ret})")
            return True
        else:
            print("⚠ Test 5: Invalid interface - Unexpected success")
            return False
    except Exception as e:
        print(f"✗ Test 5: Invalid interface - FAILED: {e}")
        test_results['errors'].append(str(e))
        return False

def test_empty_frame():
    """Test 6: Empty frame handling"""
    try:
        sta = network.WLAN(network.STA_IF)
        sta.active(True)
        time.sleep(0.5)
        
        # Try empty frame
        ret = esp_wifi_tx.wifi_80211_tx(esp_wifi_tx.WIFI_IF_STA, bytes())
        
        if ret != 0:
            print(f"✓ Test 6: Empty frame rejection - PASSED (returned {ret})")
            return True
        else:
            print("✗ Test 6: Empty frame rejection - FAILED (should reject)")
            return False
    except TypeError as e:
        print(f"✓ Test 6: Empty frame rejection - PASSED (caught: {type(e).__name__})")
        return True
    except Exception as e:
        print(f"✗ Test 6: Empty frame rejection - FAILED: {e}")
        test_results['errors'].append(str(e))
        return False

def test_minimal_frame():
    """Test 7: Send minimal valid frame"""
    try:
        sta = network.WLAN(network.STA_IF)
        sta.active(True)
        time.sleep(0.5)
        
        # Minimal frame: must be at least 24 bytes (802.11 header)
        frame = bytes([
            0x80, 0x00,  # Frame control
            0x00, 0x00,  # Duration/ID
            0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,  # Destination address
            0x11, 0x22, 0x33, 0x44, 0x55, 0x66,  # Source address
            0x11, 0x22, 0x33, 0x44, 0x55, 0x66,  # BSSID
            0x00, 0x00,  # Sequence/Fragment
            # Add minimal payload (FCS will be added by hardware)
            0x00, 0x00, 0x00, 0x00
        ])
        
        ret = esp_wifi_tx.wifi_80211_tx(esp_wifi_tx.WIFI_IF_STA, frame)
        print(f"✓ Test 7: Send minimal frame - PASSED (returned {ret})")
        return True
    except Exception as e:
        print(f"✗ Test 7: Send minimal frame - FAILED: {e}")
        test_results['errors'].append(str(e))
        return False

def test_frame_with_sys_seq_disabled():
    """Test 8: Send frame without system sequence numbering"""
    try:
        sta = network.WLAN(network.STA_IF)
        sta.active(True)
        time.sleep(0.5)
        
        frame = bytes([
            0x80, 0x00, 0x00, 0x00,
            0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
            0x11, 0x22, 0x33, 0x44, 0x55, 0x66,
            0x11, 0x22, 0x33, 0x44, 0x55, 0x66,
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00
        ])
        
        ret = esp_wifi_tx.wifi_80211_tx(esp_wifi_tx.WIFI_IF_STA, frame, False)
        print(f"✓ Test 8: Frame without sys_seq - PASSED (returned {ret})")
        return True
    except Exception as e:
        print(f"✗ Test 8: Frame without sys_seq - FAILED: {e}")
        test_results['errors'].append(str(e))
        return False

def test_ap_interface():
    """Test 9: Send frame on AP interface"""
    try:
        ap = network.WLAN(network.AP_IF)
        ap.active(True)
        time.sleep(0.5)
        
        frame = bytes([
            0x80, 0x00, 0x00, 0x00,
            0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
            0x11, 0x22, 0x33, 0x44, 0x55, 0x66,
            0x11, 0x22, 0x33, 0x44, 0x55, 0x66,
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00
        ])
        
        ret = esp_wifi_tx.wifi_80211_tx(esp_wifi_tx.WIFI_IF_AP, frame)
        print(f"✓ Test 9: AP interface frame - PASSED (returned {ret})")
        return True
    except Exception as e:
        print(f"✗ Test 9: AP interface frame - FAILED: {e}")
        test_results['errors'].append(str(e))
        return False

def run_all_tests():
    """Run all tests and print summary"""
    print("\n" + "="*50)
    print("ESP WiFi 802.11 TX Module - Test Suite")
    print("="*50 + "\n")
    
    tests = [
        test_module_import,
        test_constants_exist,
        test_function_exists,
        test_wifi_initialization,
        test_invalid_interface,
        test_empty_frame,
        test_minimal_frame,
        test_frame_with_sys_seq_disabled,
        test_ap_interface,
    ]
    
    for test in tests:
        try:
            if test():
                test_results['passed'] += 1
            else:
                test_results['failed'] += 1
        except Exception as e:
            test_results['failed'] += 1
            test_results['errors'].append(f"{test.__name__}: {e}")
        
        time.sleep(0.1)  # Small delay between tests
    
    # Print summary
    print("\n" + "="*50)
    print("Test Summary")
    print("="*50)
    print(f"Passed: {test_results['passed']}")
    print(f"Failed: {test_results['failed']}")
    print(f"Total:  {test_results['passed'] + test_results['failed']}")
    
    if test_results['errors']:
        print("\nErrors:")
        for error in test_results['errors']:
            print(f"  - {error}")
    
    if test_results['failed'] == 0:
        print("\n✓ All tests passed!")
    else:
        print(f"\n✗ {test_results['failed']} test(s) failed")
    
    print("="*50 + "\n")
    
    return test_results['failed'] == 0

# Run tests
if __name__ == "__main__":
    success = run_all_tests()
    
    # Cleanup
    sta = network.WLAN(network.STA_IF)
    ap = network.WLAN(network.AP_IF)
    sta.active(False)
    ap.active(False)

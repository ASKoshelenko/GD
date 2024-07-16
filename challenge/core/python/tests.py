#!/usr/bin/env python3
import os
import sys
import unittest
import unittest.mock

sys.path.insert(
    0, os.path.abspath(
        os.path.join(os.path.dirname(os.path.dirname(__file__)), ".."))
)

import core.python.utils

from core.python.utils import (
    extract_cgid_from_dir_name,
    ip_address_or_range_is_valid,
    normalize_scenario_name,
    find_scenario_instance_dir,
)


class TestUtilityFunctions(unittest.TestCase):
    def test_extract_cgid_from_dir_name(self):
        self.assertEqual(extract_cgid_from_dir_name("scenario6"), None)
        self.assertEqual(extract_cgid_from_dir_name("/scenario6"), None)
        self.assertEqual(extract_cgid_from_dir_name("scenarios/scenario4"),
                         None)
        self.assertEqual(extract_cgid_from_dir_name("/scenarios/scenario4"),
                         None)
        self.assertEqual(
            extract_cgid_from_dir_name("long/path/scenario3"), None
        )
        self.assertEqual(
            extract_cgid_from_dir_name("/long/path/scenario3"), None
        )
        self.assertEqual(
            extract_cgid_from_dir_name("long/path/scenario5/even/longer/path"),
            None
        )
        self.assertEqual(
            extract_cgid_from_dir_name("/long/path/scenario5/even/longer/path"),
            None
        )

        self.assertEqual(
            extract_cgid_from_dir_name("scenario6_cgid0123456789"),
            "cgid0123456789",
        )
        self.assertEqual(
            extract_cgid_from_dir_name("/scenario6_cgid0123456789"),
            "cgid0123456789",
        )
        self.assertEqual(
            extract_cgid_from_dir_name("scenarios/scenario4_cgid0123456789"),
            "cgid0123456789",
        )
        self.assertEqual(
            extract_cgid_from_dir_name("/scenarios/scenario4_cgid0123456789"),
            "cgid0123456789",
        )
        self.assertEqual(
            extract_cgid_from_dir_name(
                "long/path/scenario3_cgid0123456789"
            ),
            "cgid0123456789",
        )
        self.assertEqual(
            extract_cgid_from_dir_name(
                "/long/path/scenario3_cgid0123456789"
            ),
            "cgid0123456789",
        )
        self.assertEqual(
            extract_cgid_from_dir_name(
                "long/path/scenario5_cgid0123456789/even/longer/path"
            ),
            "cgid0123456789",
        )
        self.assertEqual(
            extract_cgid_from_dir_name(
                "/long/path/scenario5_cgid0123456789/even/longer/path"
            ),
            "cgid0123456789",
        )

    def test_ip_address_or_range_is_valid(self):
        # IPv4 CIDR notation is required.
        self.assertEqual(ip_address_or_range_is_valid("127.0.0.1"), False)
        self.assertEqual(ip_address_or_range_is_valid("127.0.0.1/"), False)
        self.assertEqual(ip_address_or_range_is_valid("127.0.0.1//32"), False)
        self.assertEqual(ip_address_or_range_is_valid("127.0.0.1\\32"), False)

        # Octets must be valid.
        self.assertEqual(ip_address_or_range_is_valid(".0.0.1/32"), False)
        self.assertEqual(ip_address_or_range_is_valid("127.0.0./32"), False)
        self.assertEqual(ip_address_or_range_is_valid("127..0.1/32"), False)
        self.assertEqual(ip_address_or_range_is_valid("127.0..1/32"), False)
        self.assertEqual(ip_address_or_range_is_valid("127...1/32"), False)
        self.assertEqual(ip_address_or_range_is_valid("..0.1/32"), False)
        self.assertEqual(ip_address_or_range_is_valid("127..0./32"), False)
        self.assertEqual(ip_address_or_range_is_valid(".0..1/32"), False)
        self.assertEqual(ip_address_or_range_is_valid("127.0../32"), False)
        self.assertEqual(ip_address_or_range_is_valid("...1/32"), False)
        self.assertEqual(ip_address_or_range_is_valid("127.../32"), False)
        self.assertEqual(ip_address_or_range_is_valid("127.0.0.0.1/32"), False)
        self.assertEqual(ip_address_or_range_is_valid("127.0.1/32"), False)
        self.assertEqual(ip_address_or_range_is_valid("127.1/32"), False)
        self.assertEqual(ip_address_or_range_is_valid("127/32"), False)
        self.assertEqual(ip_address_or_range_is_valid("/32"), False)
        self.assertEqual(ip_address_or_range_is_valid("255.255.255.256/32"),
                         False)
        self.assertEqual(ip_address_or_range_is_valid("255.255.256.255/32"),
                         False)
        self.assertEqual(ip_address_or_range_is_valid("255.256.255.255/32"),
                         False)
        self.assertEqual(ip_address_or_range_is_valid("256.255.255.255/32"),
                         False)
        self.assertEqual(ip_address_or_range_is_valid("255.255.255.-1/32"),
                         False)
        self.assertEqual(ip_address_or_range_is_valid("255.255.-1.255/32"),
                         False)
        self.assertEqual(ip_address_or_range_is_valid("255.-1.255.255/32"),
                         False)
        self.assertEqual(ip_address_or_range_is_valid("-1.255.255.255/32"),
                         False)
        self.assertEqual(ip_address_or_range_is_valid("127.0.0.I/32"), False)
        self.assertEqual(ip_address_or_range_is_valid("127.0.O.1/32"), False)
        self.assertEqual(ip_address_or_range_is_valid("127.O.0.1/32"), False)
        self.assertEqual(ip_address_or_range_is_valid("I27.0.0.1/32"), False)
        self.assertEqual(ip_address_or_range_is_valid("0.0.0.0/32"), True)
        self.assertEqual(ip_address_or_range_is_valid("255.255.255.255/32"),
                         True)

        # Subnets must be valid.
        self.assertEqual(ip_address_or_range_is_valid("127.0.0.1/-33"), False)
        self.assertEqual(ip_address_or_range_is_valid("127.0.0.1/-32"), False)
        self.assertEqual(ip_address_or_range_is_valid("127.0.0.1/-1"), False)
        self.assertEqual(ip_address_or_range_is_valid("127.0.0.1/0"), True)
        self.assertEqual(ip_address_or_range_is_valid("127.0.0.1/O"), False)
        self.assertEqual(ip_address_or_range_is_valid("127.0.0.1/1"), True)
        self.assertEqual(ip_address_or_range_is_valid("127.0.0.1/32"), True)
        self.assertEqual(ip_address_or_range_is_valid("127.0.0.1/33"), False)

    def test_normalize_scenario_name(self):
        # Edge cases
        self.assertEqual(normalize_scenario_name(""), "")
        self.assertEqual(normalize_scenario_name("/"), "")
        self.assertEqual(normalize_scenario_name("/////"), "")

        # Simple cases, fake scenario names
        self.assertEqual(normalize_scenario_name("test_a/"), "test_a")
        self.assertEqual(normalize_scenario_name("/test_b"), "test_b")
        self.assertEqual(normalize_scenario_name("test_a/test_b"), "test_b")
        self.assertEqual(normalize_scenario_name("/test_a/test_b"), "test_b")

        # "scenarios" directory
        self.assertEqual(normalize_scenario_name("scenarios"), "scenarios")
        self.assertEqual(normalize_scenario_name("scenarios/"), "scenarios")
        self.assertEqual(normalize_scenario_name("/scenarios"), "scenarios")
        self.assertEqual(normalize_scenario_name("test_a/scenarios"),
                         "scenarios")
        self.assertEqual(normalize_scenario_name("scenarios/test_b"), "test_b")
        self.assertEqual(normalize_scenario_name("test_a/scenarios/test_b"),
                         "test_b")

        # Real scenario names
        self.assertEqual(normalize_scenario_name("scenario5/"), "scenario5")
        self.assertEqual(normalize_scenario_name("/scenario5"), "scenario5")

        self.assertEqual(
            normalize_scenario_name("scenarios/scenario5"), "scenario5"
        )
        self.assertEqual(
            normalize_scenario_name("/scenarios/scenario5"), "scenario5"
        )

        # Long paths
        self.assertEqual(
            normalize_scenario_name("/long/path/scenarios/scenario5"),
            "scenario5"
        )
        self.assertEqual(
            normalize_scenario_name("scenarios/scenario5/even/longer/path"),
            "scenario5",
        )
        self.assertEqual(
            normalize_scenario_name(
                "/long/path/scenarios/scenario5/even/longer/path"
            ),
            "scenario5",
        )

        self.assertEqual(
            normalize_scenario_name("/long/path/scenarios/not-a-real-scenario"),
            "not-a-real-scenario",
        )
        self.assertEqual(
            normalize_scenario_name(
                "scenarios/not-a-real-scenario/even/longer/path"),
            "not-a-real-scenario",
        )
        self.assertEqual(
            normalize_scenario_name(
                "/long/path/scenarios/not-a-real-scenario/even/longer/path"
            ),
            "not-a-real-scenario",
        )

        # Scenario instance paths
        self.assertEqual(
            normalize_scenario_name("scenario6_cgid0123456789"),
            "scenario6",
        )
        self.assertEqual(
            normalize_scenario_name("scenarios/scenario6_cgid0123456789"),
            "scenario6",
        )
        self.assertEqual(
            normalize_scenario_name("scenario6_cgid0123456789/scenarios"),
            "scenario6",
        )

        self.assertEqual(
            normalize_scenario_name(
                "/long/path/scenarios/scenario6_cgid0123456789"
            ),
            "scenario6",
        )
        self.assertEqual(
            normalize_scenario_name(
                "scenarios/scenario6_cgid0123456789/even/longer/path"
            ),
            "scenario6",
        )
        self.assertEqual(
            normalize_scenario_name(
                "/long/path/scenarios/scenario6_cgid0123456789/even/longer/path"
            ),
            "scenario6",
        )


class TestCloudGoatClass(unittest.TestCase):
    def test_find_scenario_instance_dir(self):
        core.python.utils.dirs_at_location = unittest.mock.Mock(return_value=[
            '/tmp/other_scenario7_cgid5o8kwrb5ir',
            '/tmp/scenario7_cgidkcjqvxvjh8',
        ])
        self.assertEqual(
            find_scenario_instance_dir('/tmp', 'scenario7'),
            '/tmp/scenario7_cgidkcjqvxvjh8',
        )
        core.python.utils.dirs_at_location.assert_called_with('/tmp')


if __name__ == "__main__":
    unittest.main()

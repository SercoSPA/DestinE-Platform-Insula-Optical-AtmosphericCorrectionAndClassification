#!/usr/bin/env python3

import os
import logging


logging.basicConfig(
    encoding="utf-8",
    level=logging.INFO,
    format="%(asctime)s %(levelname)-8s %(message)s",
    datefmt="%Y-%m-%dT%H:%M:%S",
)

def tif_to_cog(tif_path: str, output_path: str):
    """
    Converts tif to cog format
    Args:
        paths = paths class dictionary
        output_path = path folder where to save
    Returns:
        it saves the output at given directory
    """
    cog_output = os.path.join(output_path,os.path.basename(tif_path)[16:31]+"Z_c2rcc_chl.tif")

    if not os.path.exists(cog_output):
        logging.info(
            f"Converting {os.path.basename(tif_path)} in cog file"
        )  # noqa
        os.system(
            "gdal_translate "
            + "-of COG "
            + "-b 1 "
            + "-a_nodata 0 "
            + "-r nearest "
            + "-co BIGTIFF=IF_NEEDED "
            + "-co RESAMPLING=NEAREST "
            + "-co OVERVIEW_RESAMPLING=NEAREST "
            + "-co WARP_RESAMPLING=NEAREST "
            + "-co NUM_THREADS=ALL_CPUS "
            + "-mo UNIT=mg/m^3 "
            + "-mo VALUE=Algal_pigment_concentration_in_complex_waters "
            + tif_path
            + " "
            + cog_output
        )
    else:
        logging.info(
            f"cog of {os.path.basename(tif_path)} already present."
        )  # noqa

#!/usr/bin/env python3

import click
import glob
import os
import logging
from extract_tif_utils import tif_to_cog


logging.basicConfig(
    encoding="utf-8",
    level=logging.INFO,
    format="%(asctime)s %(levelname)-8s %(message)s",
    datefmt="%Y-%m-%dT%H:%M:%S",
)

@click.command()
@click.option(
    "-input_path",
    default="inputs",
    help="Folder containing inputs i.e. nc file",
    )

@click.option(
    "-output_path",
    default="output_folder",
    help="Folder to save outputs i.e. Cloud Optimized GeoTIFF of chlorophyll perc. concentration",
)


def main(**kwargs):
    input_path = kwargs["input_path"]
    output_path = kwargs["output_path"]

    tif_path=glob.glob(os.path.join(input_path,"*.tif"))[0]

    tif_to_cog(tif_path,output_path)

if __name__ == "__main__":
    main()

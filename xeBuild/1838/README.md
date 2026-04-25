## How to use

Build and flash it like any other XDKBuild image. You'll need to be on the latest release of JRunner. Don't expect any homebrew to work- 1838 is XEX1, *99.999999%* of the homebrew that exists is XEX2

## What's supported?

The 1838 kernel has the following restrictions:

- Console: Phat only. Officially that means early serviced Xenon or Zephyr_A, but if you're crazy enough to install a Y1 on a tonasket it will proably work fine too.
- GPU: Fixed Y1 is the *only* GPU that will work glitch free and at full performance. Defective Y1 or earlier GPUs will work too... but like... they're defective.
- NAND: Devkit or Zero fuse supports both 16mb and 64mb. Due to xeBuild limitations, only 16mb is supported for glitch2m.

> [!CAUTION]
> If it wasn't clear, 1838 won't work properly unless you've got a Y1 GPU. When running on a Rhea or Zeus video output will randomly crash or glitch out as if you had a failing GPU. When it is not glitching, performance on Rhea and Zeus is 25% of what it is on a Y1

> [!IMPORTANT]
> Systems that use 16mb NAND chips must put the "1838-fs" folder on the root of the hard drive to be able to boot to dash or xshell. Unlike 17489, there's not enough room on the flash for a "base" set of files that can boot to a menu of some sort.
>
> In addition, kernel 1838 has zero support for retail formatted hard drives. It MUST be dev formatted. Xbox 360 neighborhood does work, so if you've got a dev formatted hard drive you can boot the system, and when it hangs at the end of the boot animation, copy the files over. Alternatively, you'll need to use a FATX injector program.

## Preparing the hard drive with the zfBuild `hdd.tools.py`

> [!CAUTION]
> The following steps will erase and format the hard drive! Make sure a backup of all important data is taken!

As of the writing of this guide, you will need a linux environment with python3 installed. I used a virtual machine of linux mint and attached the drive in question with USB passthrough. WSL will NOT work as it does not have low level access to the drive. Native windows might work if you use the raw device path (`\\.\PhysicalDriveN` etc.) but is untested. This guide was tested with a 20gb retail hard drive. Larger sizes will likely work fine.

1. Back up the hard drive data!!!!
2. Determine the physical path of the attached hard drive. This can be done on linux with `sudo lshw -class disk`. You should see a `disk` with the appropriate `size` in the output. The `logical name`, such as `/dev/sdb` is what you will use in future commands.
3. Back up the security sector: `sudo python3 hdd.tools.py --drive <physical drive> --backup-ss <path to ss backup>`
   * Example: `sudo python3 hdd.tools.py --drive /dev/sdb --backup-ss ~/Desktop/hddss.bin`
4. Create the new partition table: `sudo python3 hdd.tools.py --drive <physical drive> -dg -c`
5. Format the drive: `sudo python3 hdd.tools.py --drive /dev/sdb --format-all`
6. For 16mb consoles, inject the 1838-fs folder: `sudo python3 hdd.tools.py --drive /dev/sdb --insert <path to 1838-fs folder>`
   * Example: `sudo python3 hdd.tools.py --drive /dev/sdb --insert ~/Desktop/1838-fs`
7. Optional: inject any folders containing tools with syntax similar to step 6. However, Xbox 360 neighborhood is fully supported in 1838 so you can alternatively boot the system and copy files over the network.

## Credits

- sk1080 for help getting this going and for the hard drive script
- XDKBuild VFuse patches and flag fixer: xvistaman2005
- 360hub Discord Server - https://discord.gg/z9r3HMUxp7
- RGLoader Discord Server - https://discord.gg/jTDT4rAh56

... and anyone else i may have forgotten
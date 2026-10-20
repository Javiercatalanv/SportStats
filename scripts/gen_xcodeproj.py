#!/usr/bin/env python3
"""Genera SportStats.xcodeproj (formato Xcode 15) a partir de Frontend/ y Backend/."""
import hashlib
import os
import sys

root = sys.argv[1]
src_dirs = ["Frontend", "Backend"]
name = "SportStats"
bundle_id = "cl.ninaspro.sportstats"


def uid(*parts):
    return hashlib.md5("/".join(parts).encode()).hexdigest()[:24].upper()


objects = []  # (id, text)
children_of = {}  # group path -> list of ids
sources = []  # (buildfile id, fileref id, name)
resources = []

walk = [step for src_dir in src_dirs for step in os.walk(os.path.join(root, src_dir))]
for dirpath, dirnames, filenames in walk:
    dirnames[:] = sorted(d for d in dirnames if not d.startswith(".") and not d.endswith(".xcassets"))
    rel = os.path.relpath(dirpath, root)
    children_of.setdefault(rel, [])
    for d in dirnames:
        children_of[rel].append(("group", os.path.join(rel, d)))
    entries = sorted(filenames)
    # Los catálogos de assets se tratan como archivos.
    for d in sorted(os.listdir(dirpath)):
        if d.endswith(".xcassets"):
            entries.append(d)
    for f in entries:
        if f.startswith("."):
            continue
        path = os.path.join(rel, f)
        if f.endswith(".swift"):
            ftype = "sourcecode.swift"
        elif f.endswith(".xcassets"):
            ftype = "folder.assetcatalog"
        else:
            continue
        fid = uid("file", path)
        objects.append((fid, f'{fid} /* {f} */ = {{isa = PBXFileReference; lastKnownFileType = {ftype}; path = "{f}"; sourceTree = "<group>"; }};'))
        children_of[rel].append(("file", fid, f))
        bid = uid("build", path)
        if f.endswith(".swift"):
            sources.append((bid, fid, f))
            objects.append((bid, f"{bid} /* {f} in Sources */ = {{isa = PBXBuildFile; fileRef = {fid} /* {f} */; }};"))
        else:
            resources.append((bid, fid, f))
            objects.append((bid, f"{bid} /* {f} in Resources */ = {{isa = PBXBuildFile; fileRef = {fid} /* {f} */; }};"))

for rel, kids in children_of.items():
    gid = uid("group", rel)
    items = []
    for k in kids:
        if k[0] == "group":
            items.append(f"{uid('group', k[1])} /* {os.path.basename(k[1])} */,")
        else:
            items.append(f"{k[1]} /* {k[2]} */,")
    base = os.path.basename(rel)
    objects.append((gid, f'{gid} /* {base} */ = {{isa = PBXGroup; children = ({" ".join(items)}); path = "{base}"; sourceTree = "<group>"; }};'))

product = uid("product")
products_group = uid("productsgroup")
main_group = uid("maingroup")
target = uid("target")
project = uid("project")
src_phase, res_phase, fw_phase = uid("srcphase"), uid("resphase"), uid("fwphase")
proj_cfgs = uid("projcfglist")
tgt_cfgs = uid("tgtcfglist")
proj_debug, proj_release = uid("projdebug"), uid("projrelease")
tgt_debug, tgt_release = uid("tgtdebug"), uid("tgtrelease")

src_groups = " ".join("%s /* %s */," % (uid("group", d), d) for d in src_dirs)
objects += [
    (product, f'{product} /* {name}.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = {name}.app; sourceTree = BUILT_PRODUCTS_DIR; }};'),
    (products_group, f"{products_group} /* Products */ = {{isa = PBXGroup; children = ({product} /* {name}.app */,); name = Products; sourceTree = \"<group>\"; }};"),
    (main_group, f"{main_group} = {{isa = PBXGroup; children = ({src_groups} {products_group} /* Products */,); sourceTree = \"<group>\"; }};"),
    (src_phase, f"{src_phase} /* Sources */ = {{isa = PBXSourcesBuildPhase; buildActionMask = 2147483647; files = ({' '.join(f'{b} /* {n} in Sources */,' for b, _, n in sources)}); runOnlyForDeploymentPostprocessing = 0; }};"),
    (res_phase, f"{res_phase} /* Resources */ = {{isa = PBXResourcesBuildPhase; buildActionMask = 2147483647; files = ({' '.join(f'{b} /* {n} in Resources */,' for b, _, n in resources)}); runOnlyForDeploymentPostprocessing = 0; }};"),
    (fw_phase, f"{fw_phase} /* Frameworks */ = {{isa = PBXFrameworksBuildPhase; buildActionMask = 2147483647; files = (); runOnlyForDeploymentPostprocessing = 0; }};"),
    (target, f"{target} /* {name} */ = {{isa = PBXNativeTarget; buildConfigurationList = {tgt_cfgs}; buildPhases = ({src_phase} /* Sources */, {fw_phase} /* Frameworks */, {res_phase} /* Resources */,); buildRules = (); dependencies = (); name = {name}; productName = {name}; productReference = {product} /* {name}.app */; productType = \"com.apple.product-type.application\"; }};"),
    (project, f"{project} /* Project object */ = {{isa = PBXProject; attributes = {{BuildIndependentTargetsInParallel = 1; LastSwiftUpdateCheck = 1500; LastUpgradeCheck = 1500; TargetAttributes = {{{target} = {{CreatedOnToolsVersion = 15.0;}};}};}}; buildConfigurationList = {proj_cfgs}; compatibilityVersion = \"Xcode 14.0\"; developmentRegion = es; hasScannedForEncodings = 0; knownRegions = (es, en, Base,); mainGroup = {main_group}; productRefGroup = {products_group} /* Products */; projectDirPath = \"\"; projectRoot = \"\"; targets = ({target} /* {name} */,); }};"),
]

common_proj = """ALWAYS_SEARCH_USER_PATHS = NO; ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = YES; CLANG_ENABLE_MODULES = YES; CLANG_ENABLE_OBJC_ARC = YES; COPY_PHASE_STRIP = NO; ENABLE_STRICT_OBJC_MSGSEND = YES; ENABLE_USER_SCRIPT_SANDBOXING = YES; GCC_C_LANGUAGE_STANDARD = gnu17; IPHONEOS_DEPLOYMENT_TARGET = 17.0; LOCALIZATION_PREFERS_STRING_CATALOGS = YES; MTL_FAST_MATH = YES; SDKROOT = iphoneos;"""
objects += [
    (proj_debug, f"{proj_debug} /* Debug */ = {{isa = XCBuildConfiguration; buildSettings = {{{common_proj} DEBUG_INFORMATION_FORMAT = dwarf; ENABLE_TESTABILITY = YES; GCC_OPTIMIZATION_LEVEL = 0; GCC_PREPROCESSOR_DEFINITIONS = (\"DEBUG=1\", \"$(inherited)\",); ONLY_ACTIVE_ARCH = YES; SWIFT_ACTIVE_COMPILATION_CONDITIONS = \"DEBUG $(inherited)\"; SWIFT_OPTIMIZATION_LEVEL = \"-Onone\";}}; name = Debug; }};"),
    (proj_release, f"{proj_release} /* Release */ = {{isa = XCBuildConfiguration; buildSettings = {{{common_proj} DEBUG_INFORMATION_FORMAT = \"dwarf-with-dsym\"; ENABLE_NS_ASSERTIONS = NO; SWIFT_COMPILATION_MODE = wholemodule; VALIDATE_PRODUCT = YES;}}; name = Release; }};"),
]
common_tgt = f"""ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon; CODE_SIGN_STYLE = Automatic; CURRENT_PROJECT_VERSION = 1; DEVELOPMENT_TEAM = ""; ENABLE_PREVIEWS = YES; GENERATE_INFOPLIST_FILE = YES; INFOPLIST_KEY_CFBundleDisplayName = SportStats; INFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES; INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents = YES; INFOPLIST_KEY_UILaunchScreen_Generation = YES; INFOPLIST_KEY_UISupportedInterfaceOrientations = UIInterfaceOrientationPortrait; LD_RUNPATH_SEARCH_PATHS = ("$(inherited)", "@executable_path/Frameworks",); MARKETING_VERSION = 1.0; PRODUCT_BUNDLE_IDENTIFIER = {bundle_id}; PRODUCT_NAME = "$(TARGET_NAME)"; SWIFT_EMIT_LOC_STRINGS = YES; SWIFT_VERSION = 5.0; TARGETED_DEVICE_FAMILY = 1;"""
objects += [
    (tgt_debug, f"{tgt_debug} /* Debug */ = {{isa = XCBuildConfiguration; buildSettings = {{{common_tgt}}}; name = Debug; }};"),
    (tgt_release, f"{tgt_release} /* Release */ = {{isa = XCBuildConfiguration; buildSettings = {{{common_tgt}}}; name = Release; }};"),
    (proj_cfgs, f"{proj_cfgs} = {{isa = XCConfigurationList; buildConfigurations = ({proj_debug} /* Debug */, {proj_release} /* Release */,); defaultConfigurationIsVisible = 0; defaultConfigurationName = Release; }};"),
    (tgt_cfgs, f"{tgt_cfgs} = {{isa = XCConfigurationList; buildConfigurations = ({tgt_debug} /* Debug */, {tgt_release} /* Release */,); defaultConfigurationIsVisible = 0; defaultConfigurationName = Release; }};"),
]

body = "\n".join("\t\t" + text for _, text in sorted(objects))
pbx = f"""// !$*UTF8*$!
{{
\tarchiveVersion = 1;
\tclasses = {{
\t}};
\tobjectVersion = 56;
\tobjects = {{
{body}
\t}};
\trootObject = {project} /* Project object */;
}}
"""
out = os.path.join(root, f"{name}.xcodeproj")
os.makedirs(out, exist_ok=True)
with open(os.path.join(out, "project.pbxproj"), "w") as fh:
    fh.write(pbx)
print(f"{len(sources)} swift files, {len(resources)} resources -> {out}")

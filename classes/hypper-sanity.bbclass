# Provide some extensions to sanity.bbclass to handle hypper-specific conf file upgrades

python hypper_update_bblayersconf() {
    current_version = int(d.getVar('HYPPER_BBLAYERS_CONF_VERSION', True) or -1)
    latest_version = int(d.getVar('REQUIRED_HYPPER_BBLAYERS_CONF_VERSION', True) or -1)
    if current_version == -1 or latest_version == -1:
        # one or the other missing => malformed configuration
        raise NotImplementedError("You need to update bblayers.conf manually for this version transition")

    success = True

    # check for out of date templateconf.cfg file
    lines = []
    fn = os.path.join(d.getVar('TOPDIR', True), 'conf/templateconf.cfg')

    lines = sanity_conf_read(fn)
    index, meta_yocto_line = sanity_conf_find_line(r'^meta-yocto/', lines)
    if meta_yocto_line:
        lines[index] = meta_yocto_line.replace('meta-yocto', 'meta-hypper')
        with open(fn, "w") as f:
            f.write(''.join(lines))
        bb.note("Your conf/templateconf.cfg file was updated from meta-yocto to meta-hypper")

    # add any additional layer checks/changes here

    if success:
        current_version = latest_version
        bblayers_fn = bblayers_conf_file(d)
        lines = sanity_conf_read(bblayers_fn)
        # sanity_conf_update() will erroneously find a match when the var name
        # is used in a comment, so do our own here. The code below can be
        # removed when sanity_conf_update() is fixed in OE-Core.
        #sanity_conf_update(bblayers_fn, lines, 'HYPPER_BBLAYERS_CONF_VERSION', current_version)
        index, line = sanity_conf_find_line(r'^HYPPER_BBLAYERS_CONF_VERSION', lines)
        lines[index] = 'HYPPER_BBLAYERS_CONF_VERSION = "%d"\n' % current_version
        with open(bblayers_fn, "w") as f:
            f.write(''.join(lines))
        bb.note("Your conf/bblayers.conf has been automatically updated.")
    if success:
        return

    raise NotImplementedError("You need to update bblayers.conf manually for this version transition")
}

# ensure our function runs after the OE-Core one
BBLAYERS_CONF_UPDATE_FUNCS += "conf/bblayers.conf:HYPPER_BBLAYERS_CONF_VERSION:REQUIRED_HYPPER_BBLAYERS_CONF_VERSION:hypper_update_bblayersconf"

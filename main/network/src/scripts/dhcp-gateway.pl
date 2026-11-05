#!/usr/bin/perl

# Copyright (C) 2005-2007 Warp Networks S.L.
# Copyright (C) 2008-2013 Zentyal S.L.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License, version 2, as
# published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

use strict;
use warnings;

my ($iface, $router) = @ARGV;

use File::Slurp;

write_file("/var/lib/zentyal/conf/${iface}_gw", $router);

use EBox;
use EBox::Global;
use TryCatch;

EBox::init();

my $network = EBox::Global->modInstance('network');

EBox::debug("Called dhcp-gateway.pl with the following values: iface '$iface' router '$router'");

$iface or exit;
$router or exit;

# NetworkManager reports IP4_GATEWAY as 0.0.0.0 when the lease carries no
# router (e.g. a DHCP server that does not advertise one, or a bond whose
# slaves are on different subnets). That is not a gateway, so there is
# nothing to store, but the routing must still be regenerated: a lease event
# re-adds the DHCP default route to the main table and the multi-WAN routing
# has to remove it again.
if ($router eq '0.0.0.0') {
    try {
        $network->regenGatewaysOnEvent();
    } catch {
    }
    exit;
}

try {
    $network->setDHCPGateway($iface, $router);

    # Regenerate the routing unless there are pending changes or a save is in
    # progress.
    $network->regenGatewaysOnEvent();
} catch {
}

exit;

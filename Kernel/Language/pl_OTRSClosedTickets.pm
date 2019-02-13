# --
# Copyright (C) 2001-2019 OTRS AG, https://otrs.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::Language::pl_OTRSClosedTickets;

use strict;
use warnings;
use utf8;

sub Data {
    my $Self = shift;

    # $$START$$

    # OTRSClosedTickets.xml
    $Self->{Translation}->{'Overview of all closed tickets.'}   = 'Przegląd wszystkich zgłoszeń zamkniętych';
    $Self->{Translation}->{'Closed tickets view'} = 'Widok zgłoszeń zamkniętych';
    $Self->{Translation}->{'CloseTime'} = 'Data zamknięcia';

    # $$STOP$$
    return;
}

1;

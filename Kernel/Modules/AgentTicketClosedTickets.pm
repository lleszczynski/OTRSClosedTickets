# --
# Copyright (C) 2001-2019 OTRS AG, https://otrs.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::Modules::AgentTicketClosedTickets;

use strict;
use warnings;

use Kernel::System::VariableCheck qw(:all);
use Kernel::Language qw(Translatable);

our $ObjectManagerDisabled = 1;

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {%Param};
    bless( $Self, $Type );

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    # get needed objects
    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ParamObject  = $Kernel::OM->Get('Kernel::System::Web::Request');

    my $OrderBy = $ParamObject->GetParam( Param => 'OrderBy' ) || '';
    my $SortBy  = $ParamObject->GetParam( Param => 'SortBy' )  || '';

    $Self->_Overview(
        OrderBy => $OrderBy,
        SortBy  => $SortBy,

        # StartHit => $StartHit,
    );
    my $Output = $LayoutObject->Header();
    $Output .= $LayoutObject->NavigationBar();
    $Output .= $LayoutObject->Output(
        TemplateFile => 'AgentTicketClosedTickets',
        Data         => \%Param,
    );
    $Output .= $LayoutObject->Footer();
    return $Output;
}

sub _Overview {
    my ( $Self, %Param ) = @_;

    # initiate layout object
    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    # render overview block
    $LayoutObject->Block(
        Name => 'Overview',
        Data => \%Param,
    );

    my $OrderBy = $Param{OrderBy} || 'Down';
    my $SortBy  = $Param{SortBy}  || 'Queue';

    my @Columns = ( 'Queue', 'TicketNumber', 'Title', 'Owner', 'CloseTime' );

    for my $Column (@Columns) {

        if ( $SortBy && ( $SortBy eq $Column ) ) {
            my $TitleDesc;

            # Change order for sorting column.
            $Param{ $Column . "OrderBy" } = $OrderBy eq 'Up' ? 'Down' : 'Up';

            if ( $OrderBy eq 'Down' ) {
                $Param{ $Column . "CSS" } .= 'OverviewHeader ' . $Column . ' SortAscendingLarge';
                $Param{ $Column . "Title" } = Translatable('sorted ascending');
            }
            else {
                $Param{ $Column . "CSS" } .= 'OverviewHeader ' . $Column . ' SortDescendingLarge';
                $Param{ $Column . "Title" } = Translatable('sorted descending');
            }
        }
    }

    # initiate group object
    my $GroupObject = $Kernel::OM->Get('Kernel::System::Group');

    # check user permissions
    my $HasPermission = $GroupObject->PermissionCheck(
        UserID    => $Self->{UserID},
        GroupName => 'admin',
        Type      => 'rw',
    );

    # assign root account id if has permissions for 'admin' group
    my $UserID = $HasPermission ? 1 : $Self->{UserID};

    # initiate ticket object
    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');

    my $DateTimeObject = $Kernel::OM->Create(
        'Kernel::System::DateTime'
    );

    my $Success = $DateTimeObject->Subtract(
        Days => 7,
    );

    my $DateTimeString = $DateTimeObject->ToString();

    if ( $SortBy eq "CloseTime" ) {
        $SortBy = "";
    }

    # perform ticket search
    my @TicketIDs = $TicketObject->TicketSearch(

        # result (required)
        Result => 'ARRAY',

        # result limit
        Limit => 10_000,

        # (Open|Closed) tickets for all closed or open tickets.
        StateType => 'Closed',

        # tickets with closed time after ... (ticket closed newer than this date) (optional)
        TicketCloseTimeNewerDate => $DateTimeString,

        # OrderBy and SortBy (optional)
        OrderBy => $OrderBy || 'Down',
        SortBy  => $SortBy  || 'Age',

        # user search (UserID is required)
        UserID     => $UserID,
        Permission => 'rw',

        # CacheTTL, cache search result in seconds (optional)
        CacheTTL => 60 * 15,
    );

    # render overview result block
    $LayoutObject->Block(
        Name => 'OverviewResult',
        Data => \%Param,
    );

    # initiate user object
    my $UserObject = $Kernel::OM->Get('Kernel::System::User');

    # if there are any tickets found, they are shown
    if (@TicketIDs) {
        if ( $Param{SortBy} eq "CloseTime" ) {
            my @Tickets;

            # loop through found tickets
            for my $TicketID (@TicketIDs) {

                # get ticket info
                my %Ticket = $TicketObject->TicketGet(
                    TicketID => $TicketID,
                    UserID   => $UserID,
                );

                my %TicketGetClosed = $TicketObject->_TicketGetClosed(
                    TicketID => $TicketID,
                    Ticket   => \%Ticket,
                );

                $Ticket{CloseTime} = $TicketGetClosed{Closed};
                push @Tickets, \%Ticket;
            }

            if ( $OrderBy eq "Up" ) {
                @Tickets = sort { $a->{CloseTime} cmp $b->{CloseTime} } @Tickets;
            }
            else {
                @Tickets = sort { $b->{CloseTime} cmp $a->{CloseTime} } @Tickets;
            }

            for my $Ticket (@Tickets) {
                my %User = $UserObject->GetUserData(
                    UserID => $Ticket->{OwnerID},
                );

                # render overview result row block
                $LayoutObject->Block(
                    Name => 'OverviewResultRow',
                    Data => {
                        %{$Ticket},
                        OwnerFullName => $User{UserFullname},
                    },
                );
            }

        }
        else {
            # loop through found tickets
            for my $TicketID (@TicketIDs) {

                # get ticket info
                my %Ticket = $TicketObject->TicketGet(
                    TicketID => $TicketID,
                    UserID   => $UserID,
                );

                my %User = $UserObject->GetUserData(
                    UserID => $Ticket{OwnerID},
                );

                my %TicketGetClosed = $TicketObject->_TicketGetClosed(
                    TicketID => $TicketID,
                    Ticket   => \%Ticket,
                );

                # render overview result row block
                $LayoutObject->Block(
                    Name => 'OverviewResultRow',
                    Data => {
                        %Ticket,
                        OwnerFullName => $User{UserFullname},
                        CloseTime     => $TicketGetClosed{Closed},
                    },
                );
            }
        }
    }

    # otherwise a no data found msg is displayed
    else {
        $LayoutObject->Block(
            Name => 'NoDataFoundMsg',
            Data => {},
        );
    }
    return 1;
}

1;

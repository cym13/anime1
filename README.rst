Description
===========

Small https://www.anime1.com/ watchlist manager.

Because keeping track of where I am in what serie is troublesome.

Documentation
=============

::

    Usage: anime1 -h
           anime1 add URL
           anime1 see TITLE
           anime1 remove TITLE
           anime1 status [[TITLE] NEW_STATUS]

    Options:
        -h, --help  Print this help and exit

    Commands:
        add         Add an url to the list
        see         See the next episode of TITLE
        remove      Remove an anime by TITLE
        status      See or set the current status of all or one animes

    Arguments:
        URL         An anime1 anime URL
        TITLE       Part of an anime title.
                    Case insensitive, the first title to match is taken.
        NEW_STATUS  Integer, number of the episode in the serie

License
=======

This program is under the GPLv3 License.

You should have received a copy of the GNU General Public License
along with this program. If not, see <http://www.gnu.org/licenses/>.

Contact
=======

::

    Main developper: Cédric Picard
    Email:           cedric.picard@efrei.net

/*
 * Copyright (c) 2020 Andrew Vojak (https://avojak.com)
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public
 * License along with this program; if not, write to the
 * Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301 USA
 *
 * Authored by: Andrew Vojak <andrew.vojak@gmail.com>
 */

public class Iridium.Models.CuratedServer : GLib.Object {

    // Entries largely found at https://github.com/hexchat/hexchat/blob/master/src/common/servlist.c

    public enum Servers {
        2600NET,
        ACN,
        AFTERNET,
        AITVARAS,
        ANTHROCHAT,
        ARCNET,
        AUSTNET,
        AZZURRANET,
        CANTERNET,
        CHAT4ALL,
        CHATJUNKIES,
        CHATPAT,
        CHATSPIKE,
        DAIRC,
        DALNET,
        DARKMYST,
        DARKSCIENCE,
        DARK_TOU_NET,
        DIGITALIRC,
        DOSERSNET,
        EFNET,
        ENTERTHEGAME,
        ENTROPYNET,
        ESPERNET,
        EUIRC,
        EUROPNET,
        FDFNET,
        GAMESURGE,
        GEEKSHED,
        GERMAN_ELITE,
        GIMPNET,
        GLOBALGAMERS,
        HACKINT,
        HASHMARK,
        ICQ_CHAT,
        INTERLINKED,
        IRC_NERDS,
        IRC4FUN,
        IRCHIGHWAY,
        IRCNET,
        LIBERA_CHAT,
        OFTC,
        QUAKENET,
        RIZON,
        SNOONET,
        UNDERNET;

        public CuratedServer get_details () {
            switch (this) {
                case 2600NET:
                    return new CuratedServer () {
                        network_name = "2600net",
                        server_host = "irc.2600.net",
                        port = Iridium.Services.ServerConnectionDetails.DEFAULT_SECURE_PORT,
                        tls = true,
                        auth_method = Iridium.Models.AuthenticationMethod.NONE
                    };
                case ACN:
                    return new CuratedServer () {
                        network_name = "ACN",
                        server_host = "global.acn.gr",
                        port = Iridium.Services.ServerConnectionDetails.DEFAULT_SECURE_PORT,
                        tls = true,
                        auth_method = Iridium.Models.AuthenticationMethod.SASL_PLAIN
                    };
                case AFTERNET:
                    return new CuratedServer () {
                        network_name = "AfterNET",
                        server_host = "irc.afternet.org",
                        port = Iridium.Services.ServerConnectionDetails.DEFAULT_SECURE_PORT,
                        tls = true,
                        auth_method = Iridium.Models.AuthenticationMethod.NICKSERV_MSG
                    };
                case AITVARAS:
                    return new CuratedServer () {
                        network_name = "Aitvaras",
                        server_host = "irc.data.lt",
                        port = Iridium.Services.ServerConnectionDetails.DEFAULT_SECURE_PORT,
                        tls = true,
                        auth_method = Iridium.Models.AuthenticationMethod.NONE
                    };
                case ANTHROCHAT:
                    return new CuratedServer () {
                        network_name = "Anthrochat",
                        server_host = "irc.anthrochat.net",
                        port = Iridium.Services.ServerConnectionDetails.DEFAULT_SECURE_PORT,
                        tls = true,
                        auth_method = Iridium.Models.AuthenticationMethod.NONE
                    };
                case ARCNET:
                    return new CuratedServer () {
                        network_name = "ARCNet",
                        server_host = "arcnet-irc.org",
                        port = Iridium.Services.ServerConnectionDetails.DEFAULT_SECURE_PORT,
                        tls = true,
                        auth_method = Iridium.Models.AuthenticationMethod.NONE
                    };
                case AUSTNET:
                    return new CuratedServer () {
                        network_name = "AustNet",
                        server_host = "irc.austnet.org",
                        port = Iridium.Services.ServerConnectionDetails.DEFAULT_SECURE_PORT,
                        tls = true,
                        auth_method = Iridium.Models.AuthenticationMethod.NONE
                    };
                case AZZURRANET:
                    return new CuratedServer () {
                        network_name = "AzzurraNet",
                        server_host = "irc.azzurra.org",
                        port = Iridium.Services.ServerConnectionDetails.DEFAULT_SECURE_PORT,
                        tls = true,
                        auth_method = Iridium.Models.AuthenticationMethod.NONE
                    };
                case CANTERNET:
                    return new CuratedServer () {
                        network_name = "Canternet",
                        server_host = "irc.canternet.org",
                        port = Iridium.Services.ServerConnectionDetails.DEFAULT_SECURE_PORT,
                        tls = true,
                        auth_method = Iridium.Models.AuthenticationMethod.SASL_PLAIN
                    };
                case CHAT4ALL:
                    return new CuratedServer () {
                        network_name = "Chat4all",
                        server_host = "irc.chat4all.org",
                        port = Iridium.Services.ServerConnectionDetails.DEFAULT_SECURE_PORT,
                        tls = true,
                        auth_method = Iridium.Models.AuthenticationMethod.NONE
                    };
                case CHATJUNKIES:
                    return new CuratedServer () {
                        network_name = "ChatJunkies",
                        server_host = "irc.chatjunkies.org",
                        port = Iridium.Services.ServerConnectionDetails.DEFAULT_SECURE_PORT,
                        tls = true,
                        auth_method = Iridium.Models.AuthenticationMethod.NONE
                    };
                case CHATPAT:
                    return new CuratedServer () {
                        network_name = "Chatpat",
                        server_host = "irc.unibg.net",
                        port = Iridium.Services.ServerConnectionDetails.DEFAULT_SECURE_PORT,
                        tls = true,
                        auth_method = Iridium.Models.AuthenticationMethod.NONE
                    };
                case CHATSPIKE:
                    return new CuratedServer () {
                        network_name = "ChatSpike",
                        server_host = "irc.chatspike.net",
                        port = Iridium.Services.ServerConnectionDetails.DEFAULT_SECURE_PORT,
                        tls = true,
                        auth_method = Iridium.Models.AuthenticationMethod.NONE
                    };
                case DAIRC:
                    return new CuratedServer () {
                        network_name = "DaIRC",
                        server_host = "irc.dairc.net",
                        port = Iridium.Services.ServerConnectionDetails.DEFAULT_SECURE_PORT,
                        tls = true,
                        auth_method = Iridium.Models.AuthenticationMethod.NONE
                    };
                case DALNET:
                    return new CuratedServer () {
                        network_name = "DALnet",
                        server_host = "us.dal.net",
                        port = Iridium.Services.ServerConnectionDetails.DEFAULT_SECURE_PORT,
                        tls = true,
                        auth_method = Iridium.Models.AuthenticationMethod.NICKSERV_MSG
                    };
                case DARKMYST:
                    return new CuratedServer () {
                        network_name = "DarkMyst",
                        server_host = "irc.darkmyst.org",
                        port = Iridium.Services.ServerConnectionDetails.DEFAULT_SECURE_PORT,
                        tls = true,
                        auth_method = Iridium.Models.AuthenticationMethod.SASL_PLAIN
                    };
                case DARKSCIENCE:
                    return new CuratedServer () {
                        network_name = "darkscience",
                        server_host = "irc.darkscience.net",
                        port = Iridium.Services.ServerConnectionDetails.DEFAULT_SECURE_PORT,
                        tls = true,
                        auth_method = Iridium.Models.AuthenticationMethod.SASL_PLAIN
                    };
                case DARK_TOU_NET:
                    return new CuratedServer () {
                        network_name = "Dark-Tou-Net",
                        server_host = "irc.d-t-net.de",
                        port = Iridium.Services.ServerConnectionDetails.DEFAULT_SECURE_PORT,
                        tls = true,
                        auth_method = Iridium.Models.AuthenticationMethod.NONE
                    };
                case DIGITALIRC:
                    return new CuratedServer () {
                        network_name = "DigitalIRC",
                        server_host = "irc.digitalirc.org",
                        port = Iridium.Services.ServerConnectionDetails.DEFAULT_SECURE_PORT,
                        tls = true,
                        auth_method = Iridium.Models.AuthenticationMethod.SASL_PLAIN
                    };
                case DOSERSNET:
                    return new CuratedServer () {
                        network_name = "DosersNET",
                        server_host = "irc.dosers.net",
                        port = Iridium.Services.ServerConnectionDetails.DEFAULT_SECURE_PORT,
                        tls = true,
                        auth_method = Iridium.Models.AuthenticationMethod.SASL_PLAIN
                    };
                case EFNET:
                    return new CuratedServer () {
                        network_name = "EFnet",
                        server_host = "irc.choopa.net",
                        port = Iridium.Services.ServerConnectionDetails.DEFAULT_SECURE_PORT,
                        tls = true,
                        auth_method = Iridium.Models.AuthenticationMethod.NONE
                    };
                case ENTERTHEGAME:
                    return new CuratedServer () {
                        network_name = "EnterTheGame",
                        server_host = "irc.enterthegame.com",
                        port = Iridium.Services.ServerConnectionDetails.DEFAULT_SECURE_PORT,
                        tls = true,
                        auth_method = Iridium.Models.AuthenticationMethod.NONE
                    };
                case ENTROPYNET:
                    return new CuratedServer () {
                        network_name = "EntropyNet",
                        server_host = "irc.entropynet.net",
                        port = Iridium.Services.ServerConnectionDetails.DEFAULT_SECURE_PORT,
                        tls = true,
                        auth_method = Iridium.Models.AuthenticationMethod.SASL_PLAIN
                    };
                case ESPERNET:
                    return new CuratedServer () {
                        network_name = "EsperNet",
                        server_host = "irc.esper.net",
                        port = Iridium.Services.ServerConnectionDetails.DEFAULT_SECURE_PORT,
                        tls = true,
                        auth_method = Iridium.Models.AuthenticationMethod.SASL_PLAIN
                    };
                case EUIRC:
                    return new CuratedServer () {
                        network_name = "euIRC",
                        server_host = "irc.euirc.net",
                        port = Iridium.Services.ServerConnectionDetails.DEFAULT_SECURE_PORT,
                        tls = true,
                        auth_method = Iridium.Models.AuthenticationMethod.NONE
                    };
                case EUROPNET:
                    return new CuratedServer () {
                        network_name = "EuropNet",
                        server_host = "irc.europnet.org",
                        port = Iridium.Services.ServerConnectionDetails.DEFAULT_SECURE_PORT,
                        tls = true,
                        auth_method = Iridium.Models.AuthenticationMethod.NONE
                    };
                case FDFNET:
                    return new CuratedServer () {
                        network_name = "FDFNet",
                        server_host = "irc.fdfnet.net",
                        port = Iridium.Services.ServerConnectionDetails.DEFAULT_SECURE_PORT,
                        tls = true,
                        auth_method = Iridium.Models.AuthenticationMethod.NONE
                    };
                case GAMESURGE:
                    return new CuratedServer () {
                        network_name = "GameSurge",
                        server_host = "irc.gamesurge.net",
                        port = Iridium.Services.ServerConnectionDetails.DEFAULT_SECURE_PORT,
                        tls = true,
                        auth_method = Iridium.Models.AuthenticationMethod.NONE
                    };
                case GEEKSHED:
                    return new CuratedServer () {
                        network_name = "GeekShed",
                        server_host = "irc.geekshed.net",
                        port = Iridium.Services.ServerConnectionDetails.DEFAULT_SECURE_PORT,
                        tls = true,
                        auth_method = Iridium.Models.AuthenticationMethod.NONE
                    };
                case GERMAN_ELITE:
                    return new CuratedServer () {
                        network_name = "German-Elite",
                        server_host = "irc.german-elite.net",
                        port = Iridium.Services.ServerConnectionDetails.DEFAULT_SECURE_PORT,
                        tls = true,
                        auth_method = Iridium.Models.AuthenticationMethod.NONE
                    };
                case GIMPNET:
                    return new CuratedServer () {
                        network_name = "GIMPNet",
                        server_host = "irc.gimp.org",
                        port = Iridium.Services.ServerConnectionDetails.DEFAULT_SECURE_PORT,
                        tls = true,
                        auth_method = Iridium.Models.AuthenticationMethod.NONE
                    };
                case GLOBALGAMERS:
                    return new CuratedServer () {
                        network_name = "GlobalGamers",
                        server_host = "irc.globalgamers.net",
                        port = Iridium.Services.ServerConnectionDetails.DEFAULT_SECURE_PORT,
                        tls = true,
                        auth_method = Iridium.Models.AuthenticationMethod.NONE
                    };
                case HACKINT:
                    return new CuratedServer () {
                        network_name = "hackint",
                        server_host = "irc.hackint.org",
                        port = Iridium.Services.ServerConnectionDetails.DEFAULT_SECURE_PORT,
                        tls = true,
                        auth_method = Iridium.Models.AuthenticationMethod.SASL_PLAIN
                    };
                case HASHMARK:
                    return new CuratedServer () {
                        network_name = "Hashmark",
                        server_host = "irc.hashmark.net",
                        port = Iridium.Services.ServerConnectionDetails.DEFAULT_SECURE_PORT,
                        tls = true,
                        auth_method = Iridium.Models.AuthenticationMethod.NONE
                    };
                case ICQ_CHAT:
                    return new CuratedServer () {
                        network_name = "ICQ-Chat",
                        server_host = "irc.icq-chat.com",
                        port = Iridium.Services.ServerConnectionDetails.DEFAULT_SECURE_PORT,
                        tls = true,
                        auth_method = Iridium.Models.AuthenticationMethod.SASL_PLAIN
                    };
                case INTERLINKED:
                    return new CuratedServer () {
                        network_name = "Interlinked",
                        server_host = "irc.interlinked.me",
                        port = Iridium.Services.ServerConnectionDetails.DEFAULT_SECURE_PORT,
                        tls = true,
                        auth_method = Iridium.Models.AuthenticationMethod.SASL_PLAIN
                    };
                case IRC_NERDS:
                    return new CuratedServer () {
                        network_name = "IRC-nERDs",
                        server_host = "irc.irc-nerds.net",
                        port = Iridium.Services.ServerConnectionDetails.DEFAULT_SECURE_PORT,
                        tls = true,
                        auth_method = Iridium.Models.AuthenticationMethod.SASL_PLAIN
                    };
                case IRC4FUN:
                    return new CuratedServer () {
                        network_name = "IRC4Fun",
                        server_host = "irc.irc4fun.net",
                        port = Iridium.Services.ServerConnectionDetails.DEFAULT_SECURE_PORT,
                        tls = true,
                        auth_method = Iridium.Models.AuthenticationMethod.SASL_PLAIN
                    };
                case IRCHIGHWAY:
                    return new CuratedServer () {
                        network_name = "IRCHighWay",
                        server_host = "irc.irchighway.net",
                        port = Iridium.Services.ServerConnectionDetails.DEFAULT_SECURE_PORT,
                        tls = true,
                        auth_method = Iridium.Models.AuthenticationMethod.NONE
                    };
                case IRCNET:
                    return new CuratedServer () {
                        network_name = "IRCnet",
                        server_host = "open.ircnet.net",
                        port = Iridium.Services.ServerConnectionDetails.DEFAULT_SECURE_PORT,
                        tls = true,
                        auth_method = Iridium.Models.AuthenticationMethod.NONE
                    };
                case LIBERA_CHAT:
                    return new CuratedServer () {
                        network_name = "Libera.Chat",
                        server_host = "irc.libera.chat",
                        port = Iridium.Services.ServerConnectionDetails.DEFAULT_SECURE_PORT,
                        tls = true,
                        auth_method = Iridium.Models.AuthenticationMethod.SASL_PLAIN
                    };
                case OFTC:
                    return new CuratedServer () {
                        network_name = "OFTC",
                        server_host = "irc.oftc.net",
                        port = Iridium.Services.ServerConnectionDetails.DEFAULT_SECURE_PORT,
                        tls = true,
                        auth_method = Iridium.Models.AuthenticationMethod.NONE
                    };
                case QUAKENET:
                    return new CuratedServer () {
                        network_name = "QuakeNet",
                        server_host = "irc.quakenet.org",
                        port = Iridium.Services.ServerConnectionDetails.DEFAULT_SECURE_PORT,
                        tls = true,
                        auth_method = Iridium.Models.AuthenticationMethod.NONE
                    };
                case RIZON:
                    return new CuratedServer () {
                        network_name = "Rizon",
                        server_host = "irc.rizon.net",
                        port = Iridium.Services.ServerConnectionDetails.DEFAULT_SECURE_PORT,
                        tls = true,
                        auth_method = Iridium.Models.AuthenticationMethod.NONE
                    };
                case SNOONET:
                    return new CuratedServer () {
                        network_name = "Snoonet",
                        server_host = "irc.snoonet.org",
                        port = Iridium.Services.ServerConnectionDetails.DEFAULT_SECURE_PORT,
                        tls = true,
                        auth_method = Iridium.Models.AuthenticationMethod.SASL_PLAIN
                    };
                case UNDERNET:
                    return new CuratedServer () {
                        network_name = "UnderNet",
                        server_host = "us.undernet.org",
                        port = Iridium.Services.ServerConnectionDetails.DEFAULT_SECURE_PORT,
                        tls = true,
                        auth_method = Iridium.Models.AuthenticationMethod.NONE
                    };
                default:
                    assert_not_reached ();
            }
        }

        public static Servers[] all () {
            return { 
                2600NET,
                ACN,
                AFTERNET,
                AITVARAS,
                ANTHROCHAT,
                ARCNET,
                AUSTNET,
                AZZURRANET,
                CANTERNET,
                CHAT4ALL,
                CHATJUNKIES,
                CHATPAT,
                CHATSPIKE,
                DAIRC,
                DALNET,
                DARKMYST,
                DARKSCIENCE,
                DARK_TOU_NET,
                DIGITALIRC,
                DOSERSNET,
                EFNET,
                ENTERTHEGAME,
                ENTROPYNET,
                ESPERNET,
                EUIRC,
                EUROPNET,
                FDFNET,
                GAMESURGE,
                GEEKSHED,
                GERMAN_ELITE,
                GIMPNET,
                GLOBALGAMERS,
                HACKINT,
                HASHMARK,
                ICQ_CHAT,
                INTERLINKED,
                IRC_NERDS,
                IRC4FUN,
                IRCHIGHWAY,
                IRCNET,
                LIBERA_CHAT,
                OFTC,
                QUAKENET,
                RIZON,
                SNOONET,
                UNDERNET
            };
        }

        public static Servers? get_for_network_name (string network_name) {
            foreach (var server in all ()) {
                if (server.get_details ().network_name == network_name) {
                    return server;
                }
            }
            return null;
        }
    }

    public string network_name { get; set; }
    public string server_host { get; set; }
    public uint16 port { get; set; }
    public bool tls { get; set; }
    public Iridium.Models.AuthenticationMethod auth_method { get; set; }

    private CuratedServer () {}

}

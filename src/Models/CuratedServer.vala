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
        IRCTOO,
        KEYBOARD_FAILURE,
        LIBERA_CHAT,
        LIBERTACASA,
        LIBRAIRC,
        LINKNET,
        MINDFORGE,
        MIXXNET,
        OCEANIUS,
        OFTC,
        OTHERNET,
        OZORG,
        PIK,
        PIRC_PL,
        PTNET,
        QUAKENET,
        RIZON,
        RUSNET,
        SERENITY_IRC,
        SIMOSNAP,
        SLASHNET,
        SNOONET,
        SOHBET_NET,
        SORCERYNET,
        SPOTCHAT,
        STATION51,
        STORMBIT,
        SWIFTIRC,
        SYNIRC,
        TECHTRONIX,
        TILDE_CHAT,
        TURLINET,
        TRIPSIT,
        UNDERNET,
        XERTION;

        public CuratedServer get_details () {
            switch (this) {
                case 2600NET:
                    return new CuratedServer () {
                        network_name = "2600net",
                        server_host = "irc.2600.net",
                    };
                case ACN:
                    return new CuratedServer () {
                        network_name = "ACN",
                        server_host = "global.acn.gr",
                        auth_method = Iridium.Models.AuthenticationMethod.SASL_PLAIN
                    };
                case AFTERNET:
                    return new CuratedServer () {
                        network_name = "AfterNET",
                        server_host = "irc.afternet.org",
                        auth_method = Iridium.Models.AuthenticationMethod.NICKSERV_MSG
                    };
                case AITVARAS:
                    return new CuratedServer () {
                        network_name = "Aitvaras",
                        server_host = "irc.data.lt",
                    };
                case ANTHROCHAT:
                    return new CuratedServer () {
                        network_name = "Anthrochat",
                        server_host = "irc.anthrochat.net",
                    };
                case ARCNET:
                    return new CuratedServer () {
                        network_name = "ARCNet",
                        server_host = "arcnet-irc.org",
                    };
                case AUSTNET:
                    return new CuratedServer () {
                        network_name = "AustNet",
                        server_host = "irc.austnet.org",
                    };
                case AZZURRANET:
                    return new CuratedServer () {
                        network_name = "AzzurraNet",
                        server_host = "irc.azzurra.org",
                    };
                case CANTERNET:
                    return new CuratedServer () {
                        network_name = "Canternet",
                        server_host = "irc.canternet.org",
                        auth_method = Iridium.Models.AuthenticationMethod.SASL_PLAIN
                    };
                case CHAT4ALL:
                    return new CuratedServer () {
                        network_name = "Chat4all",
                        server_host = "irc.chat4all.org",
                    };
                case CHATJUNKIES:
                    return new CuratedServer () {
                        network_name = "ChatJunkies",
                        server_host = "irc.chatjunkies.org",
                    };
                case CHATPAT:
                    return new CuratedServer () {
                        network_name = "Chatpat",
                        server_host = "irc.unibg.net",
                    };
                case CHATSPIKE:
                    return new CuratedServer () {
                        network_name = "ChatSpike",
                        server_host = "irc.chatspike.net",
                    };
                case DAIRC:
                    return new CuratedServer () {
                        network_name = "DaIRC",
                        server_host = "irc.dairc.net",
                    };
                case DALNET:
                    return new CuratedServer () {
                        network_name = "DALnet",
                        server_host = "us.dal.net",
                        auth_method = Iridium.Models.AuthenticationMethod.NICKSERV_MSG
                    };
                case DARKMYST:
                    return new CuratedServer () {
                        network_name = "DarkMyst",
                        server_host = "irc.darkmyst.org",
                        auth_method = Iridium.Models.AuthenticationMethod.SASL_PLAIN
                    };
                case DARKSCIENCE:
                    return new CuratedServer () {
                        network_name = "darkscience",
                        server_host = "irc.darkscience.net",
                        auth_method = Iridium.Models.AuthenticationMethod.SASL_PLAIN
                    };
                case DARK_TOU_NET:
                    return new CuratedServer () {
                        network_name = "Dark-Tou-Net",
                        server_host = "irc.d-t-net.de",
                    };
                case DIGITALIRC:
                    return new CuratedServer () {
                        network_name = "DigitalIRC",
                        server_host = "irc.digitalirc.org",
                        auth_method = Iridium.Models.AuthenticationMethod.SASL_PLAIN
                    };
                case DOSERSNET:
                    return new CuratedServer () {
                        network_name = "DosersNET",
                        server_host = "irc.dosers.net",
                        auth_method = Iridium.Models.AuthenticationMethod.SASL_PLAIN
                    };
                case EFNET:
                    return new CuratedServer () {
                        network_name = "EFnet",
                        server_host = "irc.choopa.net",
                    };
                case ENTERTHEGAME:
                    return new CuratedServer () {
                        network_name = "EnterTheGame",
                        server_host = "irc.enterthegame.com",
                    };
                case ENTROPYNET:
                    return new CuratedServer () {
                        network_name = "EntropyNet",
                        server_host = "irc.entropynet.net",
                        auth_method = Iridium.Models.AuthenticationMethod.SASL_PLAIN
                    };
                case ESPERNET:
                    return new CuratedServer () {
                        network_name = "EsperNet",
                        server_host = "irc.esper.net",
                        auth_method = Iridium.Models.AuthenticationMethod.SASL_PLAIN
                    };
                case EUIRC:
                    return new CuratedServer () {
                        network_name = "euIRC",
                        server_host = "irc.euirc.net",
                    };
                case EUROPNET:
                    return new CuratedServer () {
                        network_name = "EuropNet",
                        server_host = "irc.europnet.org",
                    };
                case FDFNET:
                    return new CuratedServer () {
                        network_name = "FDFNet",
                        server_host = "irc.fdfnet.net",
                    };
                case GAMESURGE:
                    return new CuratedServer () {
                        network_name = "GameSurge",
                        server_host = "irc.gamesurge.net",
                    };
                case GEEKSHED:
                    return new CuratedServer () {
                        network_name = "GeekShed",
                        server_host = "irc.geekshed.net",
                    };
                case GERMAN_ELITE:
                    return new CuratedServer () {
                        network_name = "German-Elite",
                        server_host = "irc.german-elite.net",
                    };
                case GIMPNET:
                    return new CuratedServer () {
                        network_name = "GIMPNet",
                        server_host = "irc.gimp.org",
                    };
                case GLOBALGAMERS:
                    return new CuratedServer () {
                        network_name = "GlobalGamers",
                        server_host = "irc.globalgamers.net",
                    };
                case HACKINT:
                    return new CuratedServer () {
                        network_name = "hackint",
                        server_host = "irc.hackint.org",
                        auth_method = Iridium.Models.AuthenticationMethod.SASL_PLAIN
                    };
                case HASHMARK:
                    return new CuratedServer () {
                        network_name = "Hashmark",
                        server_host = "irc.hashmark.net",
                    };
                case ICQ_CHAT:
                    return new CuratedServer () {
                        network_name = "ICQ-Chat",
                        server_host = "irc.icq-chat.com",
                        auth_method = Iridium.Models.AuthenticationMethod.SASL_PLAIN
                    };
                case INTERLINKED:
                    return new CuratedServer () {
                        network_name = "Interlinked",
                        server_host = "irc.interlinked.me",
                        auth_method = Iridium.Models.AuthenticationMethod.SASL_PLAIN
                    };
                case IRC_NERDS:
                    return new CuratedServer () {
                        network_name = "IRC-nERDs",
                        server_host = "irc.irc-nerds.net",
                        auth_method = Iridium.Models.AuthenticationMethod.SASL_PLAIN
                    };
                case IRC4FUN:
                    return new CuratedServer () {
                        network_name = "IRC4Fun",
                        server_host = "irc.irc4fun.net",
                        auth_method = Iridium.Models.AuthenticationMethod.SASL_PLAIN
                    };
                case IRCHIGHWAY:
                    return new CuratedServer () {
                        network_name = "IRCHighWay",
                        server_host = "irc.irchighway.net",
                    };
                case IRCNET:
                    return new CuratedServer () {
                        network_name = "IRCnet",
                        server_host = "open.ircnet.net",
                    };
                case IRCTOO:
                    return new CuratedServer () {
                        network_name = "IRCtoo",
                        server_host = "irc.irctoo.net",
                    };
                case KEYBOARD_FAILURE:
                    return new CuratedServer () {
                        network_name = "Keyboard-Failure",
                        server_host = "irc.kbfail.net",
                    };
                case LIBERA_CHAT:
                    return new CuratedServer () {
                        network_name = "Libera.Chat",
                        server_host = "irc.libera.chat",
                        auth_method = Iridium.Models.AuthenticationMethod.SASL_PLAIN
                    };
                case LIBERTACASA:
                    return new CuratedServer () {
                        network_name = "LibertaCasa",
                        server_host = "irc.liberta.casa",
                        auth_method = Iridium.Models.AuthenticationMethod.SASL_PLAIN
                    };
                case LIBRAIRC:
                    return new CuratedServer () {
                        network_name = "LibraIRC",
                        server_host = "irc.librairc.net",
                    };
                case LINKNET:
                    return new CuratedServer () {
                        network_name = "LinkNet",
                        server_host = "irc.link-net.org",
                        port = 7000,
                    };
                case MINDFORGE:
                    return new CuratedServer () {
                        network_name = "MindForge",
                        server_host = "irc.mindforge.org",
                        auth_method = Iridium.Models.AuthenticationMethod.SASL_PLAIN
                    };
                case MIXXNET:
                    return new CuratedServer () {
                        network_name = "MIXXnet",
                        server_host = "irc.mixxnet.net",
                    };
                case OCEANIUS:
                    return new CuratedServer () {
                        network_name = "Oceanius",
                        server_host = "irc.oceanius.com",
                        auth_method = Iridium.Models.AuthenticationMethod.SASL_PLAIN
                    };
                case OFTC:
                    return new CuratedServer () {
                        network_name = "OFTC",
                        server_host = "irc.oftc.net",
                    };
                case OTHERNET:
                    return new CuratedServer () {
                        network_name = "OtherNet",
                        server_host = "irc.othernet.org",
                    };
                case OZORG:
                    return new CuratedServer () {
                        network_name = "OzOrg",
                        server_host = "irc.oz.org",
                    };
                case PIK:
                    return new CuratedServer () {
                        network_name = "PIK",
                        server_host = "irc.krstarica.com",
                    };
                case PIRC_PL:
                    return new CuratedServer () {
                        network_name = "pirc.pl",
                        server_host = "irc.pirc.pl",
                    };
                case PTNET:
                    return new CuratedServer () {
                        network_name = "PTnet",
                        server_host = "irc.ptnet.org",
                    };
                case QUAKENET:
                    return new CuratedServer () {
                        network_name = "QuakeNet",
                        server_host = "irc.quakenet.org",
                        port = 6668,
                        tls = false,
                    };
                case RIZON:
                    return new CuratedServer () {
                        network_name = "Rizon",
                        server_host = "irc.rizon.net",
                    };
                case RUSNET:
                    return new CuratedServer () {
                        network_name = "RusNet",
                        server_host = "irc.tomsk.net",
                    };
                case SERENITY_IRC:
                    return new CuratedServer () {
                        network_name = "Serenity-IRC",
                        server_host = "irc.serenity-irc.net",
                    };
                case SIMOSNAP:
                    return new CuratedServer () {
                        network_name = "SimosNap",
                        server_host = "irc.simosnap.com",
                        auth_method = Iridium.Models.AuthenticationMethod.SASL_PLAIN
                    };
                case SLASHNET:
                    return new CuratedServer () {
                        network_name = "SlashNET",
                        server_host = "irc.slashnet.org",
                    };
                case SNOONET:
                    return new CuratedServer () {
                        network_name = "Snoonet",
                        server_host = "irc.snoonet.org",
                        auth_method = Iridium.Models.AuthenticationMethod.SASL_PLAIN
                    };
                case SOHBET_NET:
                    return new CuratedServer () {
                        network_name = "Sohbet.net",
                        server_host = "irc.sohbet.net",
                    };
                case SORCERYNET:
                    return new CuratedServer () {
                        network_name = "SorceryNet",
                        server_host = "irc.sorcery.net",
                        auth_method = Iridium.Models.AuthenticationMethod.SASL_PLAIN
                    };
                case SPOTCHAT:
                    return new CuratedServer () {
                        network_name = "SpotChat",
                        server_host = "irc.spotchat.org",
                        auth_method = Iridium.Models.AuthenticationMethod.SASL_PLAIN
                    };
                case STATION51:
                    return new CuratedServer () {
                        network_name = "Station51",
                        server_host = "irc.station51.net",
                    };
                case STORMBIT:
                    return new CuratedServer () {
                        network_name = "StormBit",
                        server_host = "irc.stormbit.net",
                        auth_method = Iridium.Models.AuthenticationMethod.SASL_PLAIN
                    };
                case SWIFTIRC:
                    return new CuratedServer () {
                        network_name = "SwiftIRC",
                        server_host = "irc.swiftirc.net",
                    };
                case SYNIRC:
                    return new CuratedServer () {
                        network_name = "synIRC",
                        server_host = "irc.synirc.net",
                    };
                case TECHTRONIX:
                    return new CuratedServer () {
                        network_name = "Techtronix",
                        server_host = "irc.techtronix.net",
                        auth_method = Iridium.Models.AuthenticationMethod.SASL_PLAIN
                    };
                case TILDE_CHAT:
                    return new CuratedServer () {
                        network_name = "tilde.chat",
                        server_host = "irc.tilde.chat",
                        auth_method = Iridium.Models.AuthenticationMethod.SASL_PLAIN
                    };
                case TURLINET:
                    return new CuratedServer () {
                        network_name = "TURLINet",
                        server_host = "irc.servx.org",
                    };
                case TRIPSIT:
                    return new CuratedServer () {
                        network_name = "TripSit",
                        server_host = "irc.tripsit.me",
                        auth_method = Iridium.Models.AuthenticationMethod.SASL_PLAIN
                    };
                case UNDERNET:
                    return new CuratedServer () {
                        network_name = "UnderNet",
                        server_host = "us.undernet.org",
                    };
                case XERTION:
                    return new CuratedServer () {
                        network_name = "Xertion",
                        server_host = "irc.xertion.org",
                        auth_method = Iridium.Models.AuthenticationMethod.SASL_PLAIN
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
                IRCTOO,
                KEYBOARD_FAILURE,
                LIBERA_CHAT,
                LIBERTACASA,
                LIBRAIRC,
                LINKNET,
                MINDFORGE,
                MIXXNET,
                OCEANIUS,
                OFTC,
                OTHERNET,
                OZORG,
                PIK,
                PIRC_PL,
                PTNET,
                QUAKENET,
                RIZON,
                RUSNET,
                SERENITY_IRC,
                SIMOSNAP,
                SLASHNET,
                SNOONET,
                SOHBET_NET,
                SORCERYNET,
                SPOTCHAT,
                STATION51,
                STORMBIT,
                SWIFTIRC,
                SYNIRC,
                TECHTRONIX,
                TILDE_CHAT,
                TURLINET,
                TRIPSIT,
                UNDERNET,
                XERTION
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

    private CuratedServer () {
        port = Iridium.Services.ServerConnectionDetails.DEFAULT_SECURE_PORT;
        tls = true;
        auth_method = Iridium.Models.AuthenticationMethod.NONE;
    }

}

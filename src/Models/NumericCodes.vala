/*
 * Copyright (c) 2019 Andrew Vojak (https://avojak.com)
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

public class Iridium.Services.NumericCodes {

    // Replies
    public const string RPL_WELCOME = "001";
    public const string RPL_YOURHOST = "002";
    public const string RPL_CREATED = "003";
    public const string RPL_MYINFO = "004";
    public const string RPL_ISUPPORT = "005";
    public const string RPL_BOUNCE = "010";
    public const string RPL_ENDOFSTATS = "219";
    public const string RPL_STATSLINKINFO = "211";
    public const string RPL_UMODEIS = "221";
    public const string RPL_SERVLIST = "234";
    public const string RPL_SERVLISTEND = "235";
    public const string RPL_LUSERCLIENT = "251";
    public const string RPL_LUSEROP = "252";
    public const string RPL_LUSERUNKNOWN = "253";
    public const string RPL_LUSERCHANNELS = "254";
    public const string RPL_LUSERME = "255";
    public const string RPL_ADMINME = "256";
    public const string RPL_ADMINLOC1 = "257";
    public const string RPL_ADMINLOC2 = "258";
    public const string RPL_ADMINEMAIL = "259";
    public const string RPL_TRYAGAIN = "263";
    public const string RPL_LOCALUSERS = "265";
    public const string RPL_GLOBALUSERS = "266";
    public const string RPL_WHOISCERTFP = "276";
    public const string RPL_NONE = "300";
    public const string RPL_AWAY = "301";
    public const string RPL_USERHOST = "302";
    public const string RPL_ISON = "303";
    public const string RPL_UNAWAY = "305";
    public const string RPL_NOWAWAY = "306";
    public const string RPL_WHOISUSER = "311";
    public const string RPL_WHOISSERVER = "312";
    public const string RPL_WHOISOPERATOR = "313";
    public const string RPL_WHOWASUSER = "314";
    public const string RPL_WHOISIDLE = "317";
    public const string RPL_ENDOFWHOIS = "318";
    public const string RPL_WHOISCHANNELS = "319";
    public const string RPL_LISTSTART = "321";
    public const string RPL_LIST = "322";
    public const string RPL_LISTEND = "323";
    public const string RPL_CHANNELMODEIS = "324";
    public const string RPL_CREATIONTIME = "329";
    public const string RPL_NOTOPIC = "331";
    public const string RPL_TOPIC = "332";
    public const string RPL_TOPICWHOTIME = "333";
    public const string RPL_INVITING = "341";
    public const string RPL_INVITELIST = "346";
    public const string RPL_ENDOFINVITELIST = "347";
    public const string RPL_EXCEPTLIST = "348";
    public const string RPL_ENDOFEXCEPTLIST = "349";
    public const string RPL_VERSION = "351";
    public const string RPL_NAMREPLY = "353";
    public const string RPL_ENDOFNAMES = "366";
    public const string RPL_BANLIST = "367";
    public const string RPL_ENDOFBANLIST = "368";
    public const string RPL_ENDOFWHOWAS = "369";
    public const string RPL_MOTDSTART = "375";
    public const string RPL_MOTD = "372";
    public const string RPL_ENDOFMOTD = "376";
    public const string RPL_YOUREOPER = "381";
    public const string RPL_REHASHING = "382";
    public const string RPL_STARTTLS = "670";
    public const string RPL_LOGGEDIN = "900";
    public const string RPL_LOGGEDOUT = "901";
    public const string RPL_SASLSUCCESS = "903";
    public const string RPL_SASLMECHS = "908";

    // Errors
    public const string ERR_UNKNOWNERROR = "400";
    public const string ERR_NOSUCHNICK = "401";
    public const string ERR_NOSUCHSERVER = "402";
    public const string ERR_NOSUCHCHANNEL = "403";
    public const string ERR_CANNOTSENDTOCHAN = "404";
    public const string ERR_TOOMANYCHANNELS = "405";
    public const string ERR_NORECIPIENT = "411";
    public const string ERR_NOTEXTTOSEND = "412";
    public const string ERR_UNKNOWNCOMMAND = "421";
    public const string ERR_NOMOTD = "422";
    public const string ERR_ERRONEOUSNICKNAME = "432";
    public const string ERR_NICKNAMEINUSE = "433";
    public const string ERR_USERNOTINCHANNEL = "441";
    public const string ERR_NOTONCHANNEL = "442";
    public const string ERR_USERONCHANNEL = "443";
    public const string ERR_NOTREGISTERED = "451";
    public const string ERR_NEEDMOREPARAMS = "461";
    public const string ERR_ALREADYREGISTERED = "462";
    public const string ERR_PASSWDMISMATCH = "464";
    public const string ERR_YOUREBANNEDCREEP = "465";
    public const string ERR_YOUWILLBEBANNED = "466";
    public const string ERR_CHANNELISFULL = "471";
    public const string ERR_UNKNOWNMODE = "472";
    public const string ERR_INVITEONLYCHAN = "473";
    public const string ERR_BANNEDFROMCHAN = "474";
    public const string ERR_BADCHANNELKEY = "475";
    public const string ERR_BADCHANMASK = "476";
    public const string ERR_NOPRIVILEGES = "481";
    public const string ERR_CHANOPRIVSNEEDED = "482";
    public const string ERR_CANTKILLSERVER = "483";
    public const string ERR_NOOPERHOST = "491";
    public const string ERR_UMODEUNKNOWNFLAG = "501";
    public const string ERR_USERSDONTMATCH = "502";
    public const string ERR_STARTTLS = "691";
    public const string ERR_NOPRIVS = "723";
    public const string ERR_NICKLOCKED = "902";
    public const string ERR_SASLFAIL = "904";
    public const string ERR_SASLTOOLONG = "905";
    public const string ERR_SASLABORTED = "906";
    public const string ERR_SASLALREADY = "907";

}

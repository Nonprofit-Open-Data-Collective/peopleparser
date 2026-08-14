#' Known Titles and Abbreviations
#'
#' Returns a reference table of known name titles, academic degrees,
#' professional credentials, military ranks, civic honorifics, and related
#' abbreviations. Each entry includes the abbreviation (`abbr`), its expanded
#' descriptive form (`label`), and a general category (`type`).
#'
#' This dataset is intended for use in name-parsing, record linkage, and entity
#' resolution applications, providing a consistent reference for recognizing and
#' expanding abbreviated titles in personal or organizational names.
#'
#' @details
#' The `type` field groups each abbreviation into broad semantic categories such as:
#' \itemize{
#'   \item \strong{Personal Title}: honorifics like "Mr", "Ms", or "Dr".
#'   \item \strong{Academic Degree}: academic or professional degrees (e.g., "PhD", "MD", "MBA").
#'   \item \strong{Religious Title}: ecclesiastical or clerical designations (e.g., "Rev", "Fr", "Sister").
#'   \item \strong{Civic / Political Title}: governmental or judicial titles (e.g., "Senator", "Judge", "Honorable").
#'   \item \strong{Military Rank / Affiliation}: formal ranks or affiliations (e.g., "Lt", "Col", "USAF").
#'   \item \strong{Professional Credential}: licensed or certified professional credentials (e.g., "CPA", "PE", "RN").
#'   \item \strong{Organizational Role}: internal titles or positions (e.g., "CEO", "VP", "Ex Officio").
#'   \item \strong{Other}: geographic or contextual markers not part of formal titles (e.g., "La", "ZL").
#' }
#'
#' @return
#' A tibble with three columns:
#' \describe{
#'   \item{abbr}{Character abbreviation or short form of the title.}
#'   \item{label}{Expanded descriptive form of the title or credential.}
#'   \item{type}{Category of the title (e.g., "Academic Degree", "Military Rank").}
#' }
#'
#' @examples
#' titles <- known_titles()
#' dplyr::filter(titles, abbr %in% c("MD", "CPA", "LT"))
#'
#' # Lookup utility example
#' title_lookup <- setNames(titles$label, titles$abbr)
#' title_lookup["PHD"]
#'
#' @seealso
#' \url{https://en.wikipedia.org/wiki/Title}, 
#' \url{https://en.wikipedia.org/wiki/List_of_post-nominal_letters}
#'
#' @export
known_titles <- function(){

  title_labels <- tibble::tribble(
    ~abbr,        ~label,                                           ~type,
    # --- Personal titles ---
    "MR",          "Mister",                                        "Personal Title",
    "MRS",         "Missus",                                        "Personal Title",
    "MISS",        "Miss",                                          "Personal Title",
    "MS",          "Ms.",                                           "Personal Title",
    "DR",          "Doctor",                                        "Personal Title",
    "DOCTOR",      "Doctor",                                        "Personal Title",

    # --- Academic / professional degrees ---
    "PHD",         "Doctor of Philosophy",                          "Academic Degree",
    "JD",          "Doctor of Jurisprudence",                       "Academic Degree",
    "MD",          "Doctor of Medicine",                            "Academic Degree",
    "DO",          "Doctor of Osteopathy",                          "Academic Degree",
    "DDS",         "Doctor of Dental Surgery",                      "Academic Degree",
    "DMD",         "Doctor of Dental Medicine",                     "Academic Degree",
    "OD",          "Doctor of Optometry",                           "Academic Degree",
    "DVM",         "Doctor of Veterinary Medicine",                 "Academic Degree",
    "DRPH",        "Doctor of Public Health",                       "Academic Degree",
    "EDD",         "Doctor of Education",                           "Academic Degree",
    "THD",         "Doctor of Theology",                            "Academic Degree",
    "VMD",         "Veterinary Medical Doctor",                     "Academic Degree",
    "DNP",         "Doctor of Nursing Practice",                    "Academic Degree",
    "MBA",         "Master of Business Administration",              "Academic Degree",
    "MPH",         "Master of Public Health",                       "Academic Degree",
    "MED",         "Master of Education",                           "Academic Degree",
    "MHS",         "Master of Health Science",                      "Academic Degree",
    "MSN",         "Master of Science in Nursing",                  "Academic Degree",
    "MSW",         "Master of Social Work",                         "Academic Degree",
    "MSC",         "Master of Science",                             "Academic Degree",
    "MSM",         "Master of Science in Management",               "Academic Degree",
    "MLN",         "Master of Leadership and Negotiation",          "Academic Degree",
    "AAS",         "Associate of Applied Science",                  "Academic Degree",
    "BS",          "Bachelor of Science",                           "Academic Degree",
    "BA",          "Bachelor of Arts",                              "Academic Degree",

    # --- Religious titles ---
    "REV",         "Reverend",                                      "Religious Title",
    "REVEREND",    "Reverend",                                      "Religious Title",
    "VERY REV",    "Very Reverend",                                 "Religious Title",
    "VERY REVEREND", "Very Reverend",                               "Religious Title",
    "FR",          "Father",                                        "Religious Title",
    "FATHER",      "Father",                                        "Religious Title",
    "RT REV",      "Right Reverend",                                "Religious Title",
    "SIS",         "Sister",                                        "Religious Title",
    "PASTOR",      "Pastor",                                        "Religious Title",
    "MSG",         "Monsignor",                                     "Religious Title",
    "MSGR",        "Monsignor",                                     "Religious Title",

    # --- Civic / political titles ---
    "HON",         "Honorable",                                     "Civic / Political Title",
    "HONORABLE",   "Honorable",                                     "Civic / Political Title",
    "THE HON",     "The Honorable",                                 "Civic / Political Title",
    "THE HONORABLE","The Honorable",                                "Civic / Political Title",
    "SENATOR",     "Senator",                                       "Civic / Political Title",
    "CONGRESSMAN", "Congressman",                                   "Civic / Political Title",
    "AMBASSADOR",  "Ambassador",                                    "Civic / Political Title",
    "GOVERNOR",    "Governor",                                      "Civic / Political Title",
    "MAYOR",       "Mayor",                                         "Civic / Political Title",
    "COMMISSIONER","Commissioner",                                  "Civic / Political Title",
    "DELEGATE",    "Delegate",                                      "Civic / Political Title",
    "SUPERINTENDENT","Superintendent",                              "Civic / Political Title",
    "JUDGE",       "Judge",                                         "Civic / Political Title",
    "THE",         "The (Honorific Prefix)",                        "Civic / Political Title",

    # --- Military ranks ---
    "GEN",         "General",                                       "Military Rank",
    "BG",          "Brigadier General",                             "Military Rank",
    "BRIG",        "Brigadier",                                     "Military Rank",
    "BRIG GEN",    "Brigadier General",                             "Military Rank",
    "MG",          "Major General",                                 "Military Rank",
    "MAJ",         "Major",                                         "Military Rank",
    "LTG",         "Lieutenant General",                            "Military Rank",
    "LTC",         "Lieutenant Colonel",                            "Military Rank",
    "LT COL",      "Lieutenant Colonel",                            "Military Rank",
    "COL",         "Colonel",                                       "Military Rank",
    "CAPT",        "Captain",                                       "Military Rank",
    "CPT",         "Captain",                                       "Military Rank",
    "LT",          "Lieutenant",                                    "Military Rank",
    "SGM",         "Sergeant Major",                                "Military Rank",
    "SGT",         "Sergeant",                                      "Military Rank",
    "MCPO",        "Master Chief Petty Officer",                    "Military Rank",
    "CW5",         "Chief Warrant Officer 5",                       "Military Rank",
    "ARNG",        "Army National Guard",                           "Military Affiliation",
    "USAF",        "U.S. Air Force",                                "Military Affiliation",
    "USAR",        "U.S. Army Reserve",                             "Military Affiliation",
    "USN",         "U.S. Navy",                                     "Military Affiliation",
    "USMC",        "U.S. Marine Corps",                             "Military Affiliation",
    "USCG",        "U.S. Coast Guard",                              "Military Affiliation",
    "NYNG",        "New York National Guard",                       "Military Affiliation",
    "TXSG",        "Texas State Guard",                             "Military Affiliation",
    "RET",         "Retired",                                       "Military Status",

    # --- Professional credentials ---
    "CFA",         "Chartered Financial Analyst",                   "Professional Credential",
    "CPA",         "Certified Public Accountant",                   "Professional Credential",
    "CIMA",        "Certified Investment Management Analyst",        "Professional Credential",
    "CFP",         "Certified Financial Planner",                   "Professional Credential",
    "CHES",        "Certified Health Education Specialist",          "Professional Credential",
    "CTP",         "Certified Treasury Professional",               "Professional Credential",
    "CSC",         "Congregation of Holy Cross",                    "Professional Credential",
    "CRS",         "Certified Residential Specialist",              "Professional Credential",
    "CIPS",        "Certified International Property Specialist",    "Professional Credential",
    "AIA",         "American Institute of Architects",               "Professional Credential",
    "RPLU",        "Registered Professional Liability Underwriter",  "Professional Credential",
    "RN",          "Registered Nurse",                               "Professional Credential",
    "RPH",         "Registered Pharmacist",                          "Professional Credential",
    "PE",          "Professional Engineer",                          "Professional Credential",
    "FACS",        "Fellow of the American College of Surgeons",     "Professional Credential",

    # --- Organizational roles ---
    "CEO",         "Chief Executive Officer",                       "Organizational Role",
    "CFO",         "Chief Financial Officer",                       "Organizational Role",
    "VP",          "Vice President",                                "Organizational Role",
    "PRES",        "President",                                     "Organizational Role",
    "SEC",         "Secretary",                                     "Organizational Role",
    "OFFICER",     "Officer",                                       "Organizational Role",
    "EX-OFFICIO",  "Ex Officio",                                    "Organizational Role",
    "OFFICIO",     "Ex Officio",                                    "Organizational Role",
    "PAST",        "Past (Title)",                                  "Organizational Role",
    "DEP",         "Deputy",                                        "Organizational Role",
    "DEF",         "Defense",                                       "Organizational Role",
    "CO",          "Commanding Officer",                            "Organizational Role",
    "EX",          "Ex Officio",                                    "Organizational Role",

    # --- Geographic / other ---
    "LA",          "Louisiana (or particle 'La')",                  "Geographic / Other",
    "EARL",        "Earl",                                          "Honorific / Nobiliary",
    "WM",          "William (Abbreviation)",                        "Personal Name Abbreviation",
    "ZL",          "Of Blessed Memory (Hebrew: Zichrono Livracha)", "Religious Honorific",
    "ZOLA",        "Zola (Name or Religious Order)",                "Other"
  )
  
  return( title_labels )

}
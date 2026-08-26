import streamlit as st
import os
import json
import uuid
from datetime import datetime

try:
    from google import genai
    from google.genai import types
    GEMINI_OK = True
except ImportError:
    GEMINI_OK = False

st.set_page_config(
    page_title="Checklist à toute épreuve",
    page_icon="✅",
    layout="centered",
    initial_sidebar_state="collapsed"
)

DATA_FILE = "checklist_toute_epreuve_v25.json"

st.markdown("""
<style>

html, body, [class*="css"], .stApp {
    color: #111827 !important;
}

.stApp {
    background: linear-gradient(135deg, #eef6ff 0%, #f8f5ff 50%, #effcff 100%);
}

.main .block-container {
    max-width: 900px;
    padding-top: 1.2rem;
    padding-bottom: 4rem;
}

.logo {
    width: 90px;
    height: 90px;
    margin: 0 auto 12px auto;
    border-radius: 27px;
    background: linear-gradient(135deg, #2563eb, #7c3aed);
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 46px;
    box-shadow: 0 18px 40px rgba(37,99,235,.28);
}

.app-title {
    text-align: center;
    font-size: 45px;
    font-weight: 900;
    color: #172554 !important;
    letter-spacing: -2px;
}

.app-subtitle {
    text-align: center;
    font-size: 17px;
    color: #334155 !important;
    margin-bottom: 25px;
}

.glass,
.feature,
.folder,
.progress-card,
.done-card,
.premium-card {
    color: #111827 !important;
}

.glass {
    padding: 24px;
    border-radius: 25px;
    background: rgba(255,255,255,.96);
    border: 1px solid #e2e8f0;
    box-shadow: 0 15px 40px rgba(15,23,42,.08);
    margin-bottom: 18px;
}

.glass h1,
.glass h2,
.glass h3,
.glass p {
    color: #111827 !important;
}

.welcome {
    padding: 27px;
    border-radius: 27px;
    color: white !important;
    background: linear-gradient(135deg, #2563eb, #4f46e5, #7c3aed);
    box-shadow: 0 20px 45px rgba(79,70,229,.28);
    margin-bottom: 20px;
}

.welcome h2,
.welcome p {
    color: white !important;
}

.feature {
    padding: 20px;
    border-radius: 22px;
    background: rgba(255,255,255,.96);
    border: 1px solid #e2e8f0;
    min-height: 140px;
    margin-bottom: 15px;
}

.feature h3,
.feature p {
    color: #111827 !important;
}

.feature-icon {
    font-size: 32px;
}

.folder {
    padding: 22px;
    border-radius: 23px;
    background: #ffffff;
    border: 2px solid #bfdbfe;
    box-shadow: 0 12px 30px rgba(37,99,235,.09);
    margin-bottom: 16px;
}

.folder h2,
.folder p {
    color: #111827 !important;
}

.progress-card {
    padding: 18px;
    border-radius: 20px;
    background: #eff6ff;
    border: 2px solid #bfdbfe;
    margin: 15px 0;
}

.progress-card h3,
.progress-card p {
    color: #111827 !important;
}

.done-card {
    padding: 18px;
    border-radius: 20px;
    background: #ecfdf5;
    border: 2px solid #34d399;
    margin: 15px 0;
}

.done-card,
.done-card b {
    color: #065f46 !important;
}

.premium-card {
    padding: 22px;
    border-radius: 23px;
    background: #fff7ed;
    border: 2px solid #f59e0b;
    margin: 18px 0;
}

.premium-card h3,
.premium-card p,
.premium-card b {
    color: #111827 !important;
}

.footer {
    text-align: center;
    color: #475569 !important;
    font-size: 13px;
    padding: 25px 5px;
}

.footer b {
    color: #111827 !important;
}

.stMarkdown,
.stMarkdown p,
.stMarkdown span,
.stText,
label,
.stCaption,
[data-testid="stCaptionContainer"] {
    color: #111827 !important;
}

.stTextInput label,
.stTextArea label,
.stNumberInput label,
.stSelectbox label,
.stFileUploader label {
    color: #111827 !important;
}

input,
textarea,
select,
[data-baseweb="select"] > div,
[data-baseweb="input"] > div {
    background-color: #ffffff !important;
    color: #111827 !important;
}

input::placeholder,
textarea::placeholder {
    color: #64748b !important;
    opacity: 1 !important;
}

[data-baseweb="select"] span {
    color: #111827 !important;
}

.stCheckbox label {
    color: #111827 !important;
}

.stCheckbox label span {
    color: #111827 !important;
}

.stRadio label {
    color: #111827 !important;
}

.stButton > button {
    border-radius: 15px;
    min-height: 48px;
    font-weight: 700;
    background-color: #ffffff !important;
    color: #111827 !important;
    border: 1px solid #cbd5e1 !important;
}

.stButton > button:hover {
    border-color: #2563eb !important;
    color: #2563eb !important;
}

[data-testid="stExpander"] {
    background-color: #ffffff !important;
    border: 1px solid #cbd5e1 !important;
}

[data-testid="stExpander"] summary,
[data-testid="stExpander"] summary p {
    color: #111827 !important;
}

[data-testid="stMetric"] {
    background-color: #ffffff !important;
    padding: 15px;
    border-radius: 15px;
    border: 1px solid #e2e8f0;
}

[data-testid="stMetricLabel"],
[data-testid="stMetricValue"] {
    color: #111827 !important;
}

hr {
    border-color: #cbd5e1 !important;
}

@media (max-width: 600px) {

    .app-title {
        font-size: 34px;
        color: #172554 !important;
    }

    .app-subtitle {
        font-size: 15px;
        color: #334155 !important;
    }

    .main .block-container {
        padding-left: 1rem;
        padding-right: 1rem;
    }

    .logo {
        width: 76px;
        height: 76px;
        font-size: 38px;
    }

    .glass,
    .feature,
    .folder,
    .progress-card,
    .done-card,
    .premium-card {
        background: #ffffff !important;
    }

    input,
    textarea,
    select {
        background-color: #ffffff !important;
        color: #111827 !important;
    }

    .stButton > button {
        background-color: #ffffff !important;
        color: #111827 !important;
    }
}

</style>
""", unsafe_allow_html=True)


def donnees_vides():
    return {
        "version": "25",
        "profil": None,
        "dossiers": []
    }


def charger_donnees():

    if not os.path.exists(DATA_FILE):
        return donnees_vides()

    try:
        with open(DATA_FILE, "r", encoding="utf-8") as fichier:
            data = json.load(fichier)

        if not isinstance(data, dict):
            return donnees_vides()

        data.setdefault("profil", None)
        data.setdefault("dossiers", [])

        return data

    except Exception:
        return donnees_vides()


def sauvegarder():

    data = {
        "version": "25",
        "profil": st.session_state.profil,
        "dossiers": st.session_state.dossiers
    }

    try:
        with open(DATA_FILE, "w", encoding="utf-8") as fichier:
            json.dump(
                data,
                fichier,
                indent=4,
                ensure_ascii=False
            )

        return True

    except Exception:
        return False


data = charger_donnees()

if "profil" not in st.session_state:
    st.session_state.profil = data["profil"]

if "dossiers" not in st.session_state:
    st.session_state.dossiers = data["dossiers"]

if "page" not in st.session_state:
    st.session_state.page = "🏠 Accueil"

if "dossier_ouvert" not in st.session_state:
    st.session_state.dossier_ouvert = None


def nouvel_id():
    return str(uuid.uuid4())


def maintenant():
    return datetime.now().strftime("%d/%m/%Y à %H:%M")


def creer_dossier(nom, documents):

    return {
        "id": nouvel_id(),
        "nom": nom,
        "date_creation": maintenant(),
        "documents": documents,
        "documents_coches": [],
        "analyses": []
    }


def calculer_progression(dossier):

    documents = dossier.get("documents", [])
    coches = dossier.get("documents_coches", [])

    total = len(documents)

    if total == 0:
        return 0, 0, 0

    faits = sum(
        1 for document in documents
        if document in coches
    )

    pourcentage = round(faits / total * 100)

    return faits, total, pourcentage


def obtenir_cle_gemini():

    try:
        cle = st.secrets.get("GEMINI_API_KEY")

        if cle:
            return str(cle).strip()

    except Exception:
        pass

    return None


def gemini_configure():
    return bool(obtenir_cle_gemini())


def obtenir_client_gemini():

    if not GEMINI_OK:
        return None

    cle = obtenir_cle_gemini()

    if not cle:
        return None

    try:
        return genai.Client(api_key=cle)

    except Exception:
        return None


def checklist_demarche(situation, logement):

    documents = [
        "Pièce d'identité",
        "Justificatif de domicile récent"
    ]

    if situation == "Carte d'identité":

        documents += [
            "Photo d'identité conforme",
            "Ancienne carte d'identité si disponible"
        ]

    elif situation == "Passeport":

        documents += [
            "Photo d'identité conforme",
            "Ancien passeport si disponible"
        ]

    elif situation == "Permis de conduire":

        documents += [
            "Photo-signature numérique",
            "Justificatif d'identité",
            "Avis médical si nécessaire"
        ]

    elif situation == "Changement d'adresse":

        documents += [
            "Ancienne adresse",
            "Nouvelle adresse"
        ]

    elif situation == "Inscription scolaire":

        documents += [
            "Livret de famille ou document équivalent",
            "Documents concernant l'enfant"
        ]

    elif situation == "Création d'entreprise":

        documents += [
            "Adresse de l'entreprise",
            "Informations sur l'activité",
            "Statut juridique choisi"
        ]

    if logement == "Je suis hébergé chez quelqu'un":

        documents += [
            "Attestation d'hébergement",
            "Justificatif de domicile de l'hébergeant"
        ]

    resultat = []

    for document in documents:

        if document not in resultat:
            resultat.append(document)

    return resultat


def analyser_document(fichier, nom_demarche, checklist):

    client = obtenir_client_gemini()

    if client is None:
        return None

    checklist_text = "\n".join(
        "- " + document
        for document in checklist
    )

    prompt = f"""
Tu es l'assistant documentaire de
"Checklist à toute épreuve".

Démarche :
{nom_demarche}

Documents attendus :
{checklist_text}

Analyse le document fourni.

Réponds en français.

Utilise exactement cette structure :

DOCUMENT_RECONNU:
...

CORRESPONDANCE:
...

STATUT:
CORRECT / INCORRECT / NON_RECONNU

EXPLICATION:
...

POINTS_A_VERIFIER:
...

CONCLUSION:
...

Règles importantes :

- Ne devine aucune information.
- Si le document est illisible, indique-le.
- Si ce n'est pas un document administratif, indique-le.
- Ne donne aucune garantie juridique.
- Ne dis jamais qu'un document sera forcément accepté.
- Signale clairement les éléments qui doivent être vérifiés
  par l'utilisateur ou l'administration.
"""

    try:

        response = client.models.generate_content(
            model="gemini-3.6-flash",
            contents=[
                types.Part.from_bytes(
                    data=fichier.getvalue(),
                    mime_type=fichier.type
                ),
                prompt
            ]
        )

        return response.text

    except Exception as erreur:

        return "ERREUR_ANALYSE\n" + str(erreur)


def assistant_gemini(question):

    client = obtenir_client_gemini()

    if client is None:
        return None

    prompt = f"""
Tu es l'assistant administratif de
"Checklist à toute épreuve".

Question :
{question}

Réponds en français avec des explications simples.

Règles :

- Ne devine aucune information.
- Ne présente pas ta réponse comme officielle.
- Si la réponse dépend de la situation personnelle,
  précise-le.
- Conseille de vérifier les informations auprès
  de l'administration officielle concernée.
"""

    try:

        response = client.models.generate_content(
            model="gemini-3.6-flash",
            contents=prompt
        )

        return response.text

    except Exception as erreur:

        return "Une erreur est survenue : " + str(erreur)


if st.session_state.profil is None:

    st.markdown('<div class="logo">✅</div>', unsafe_allow_html=True)

    st.markdown(
        '<div class="app-title">Checklist à toute épreuve</div>',
        unsafe_allow_html=True
    )

    st.markdown(
        '<div class="app-subtitle">Votre assistant pour préparer vos démarches administratives.</div>',
        unsafe_allow_html=True
    )

    st.markdown(
        """
        <div class="glass">
        <h2>👋 Bienvenue !</h2>
        <p>Créez votre profil pour commencer à préparer vos démarches.</p>
        <p>🆓 Version actuelle gratuite</p>
        </div>
        """,
        unsafe_allow_html=True
    )

    prenom = st.text_input("Prénom")
    nom = st.text_input("Nom", placeholder="Facultatif")
    email = st.text_input("Email")

    age = st.number_input(
        "Âge",
        min_value=1,
        max_value=120,
        value=18
    )

    nationalite = st.selectbox(
        "Nationalité",
        ["Française", "Européenne", "Autre"]
    )

    logement = st.selectbox(
        "Situation de logement",
        [
            "Je suis propriétaire",
            "Je suis locataire",
            "Je suis hébergé chez quelqu'un"
        ]
    )

    if st.button(
        "🚀 Créer mon profil",
        use_container_width=True
    ):

        if not prenom.strip():
            st.warning("⚠️ Indiquez votre prénom.")

        elif not email.strip():
            st.warning("⚠️ Indiquez votre adresse email.")

        else:

            st.session_state.profil = {
                "prenom": prenom.strip(),
                "nom": nom.strip(),
                "email": email.strip().lower(),
                "age": int(age),
                "nationalite": nationalite,
                "logement": logement
            }

            sauvegarder()

            st.success("🎉 Profil créé !")
            st.rerun()

    st.stop()


profil = st.session_state.profil

st.markdown('<div class="logo">✅</div>', unsafe_allow_html=True)

st.markdown(
    '<div class="app-title">Checklist à toute épreuve</div>',
    unsafe_allow_html=True
)

st.markdown(
    '<div class="app-subtitle">Simple • Clair • Organisé</div>',
    unsafe_allow_html=True
)


pages = [
    "🏠 Accueil",
    "➕ Nouvelle démarche",
    "📋 Mes dossiers",
    "🤖 Assistant",
    "👤 Profil"
]


if st.session_state.page not in pages:
    st.session_state.page = pages[0]


page = st.radio(
    "Navigation",
    pages,
    index=pages.index(st.session_state.page),
    horizontal=True,
    label_visibility="collapsed"
)

st.session_state.page = page

st.divider()


def afficher_dossier(dossier):

    st.markdown(
        f"""
        <div class="folder">
        <h2>📋 {dossier["nom"]}</h2>
        <p>Créé le {dossier["date_creation"]}</p>
        </div>
        """,
        unsafe_allow_html=True
    )

    faits, total, pourcentage = calculer_progression(dossier)

    st.markdown(
        f"""
        <div class="progress-card">
        <h3>📊 Progression</h3>
        <p><b>{faits}</b> document(s) vérifié(s) sur <b>{total}</b>.</p>
        </div>
        """,
        unsafe_allow_html=True
    )

    st.progress(pourcentage / 100)

    st.write(f"**{pourcentage}% terminé**")

    if pourcentage == 100:

        st.markdown(
            """
            <div class="done-card">
            🎉 <b>Dossier prêt !</b><br>
            Tous les documents de la checklist sont cochés.
            </div>
            """,
            unsafe_allow_html=True
        )

    st.markdown("### ✅ Ma checklist")

    st.caption("Coche les documents que tu possèdes déjà.")

    with st.form(key="checklist_form_" + dossier["id"]):

        nouvelles_cases = {}

        for i, document in enumerate(
            dossier.get("documents", [])
        ):

            nouvelles_cases[document] = st.checkbox(
                document,
                value=document in dossier.get(
                    "documents_coches",
                    []
                ),
                key="document_" + dossier["id"] + "_" + str(i)
            )

        sauvegarder_checklist = st.form_submit_button(
            "💾 Enregistrer la checklist",
            use_container_width=True
        )

    if sauvegarder_checklist:

        dossier["documents_coches"] = [
            document
            for document, coche in nouvelles_cases.items()
            if coche
        ]

        sauvegarder()

        st.success("✅ Checklist enregistrée !")

        st.session_state.dossier_ouvert = dossier["id"]

        st.rerun()

    st.divider()

    st.markdown("### 📄 Vérifier un document")

    st.markdown(
        """
        <div class="premium-card">
        <h3>🤖 Vérification intelligente</h3>
        <p>
        Importez une photo ou un scan d'un document.
        L'assistant peut comparer le document avec votre checklist.
        </p>
        <b>⚠️ Cette fonction utilise une IA et ne remplace pas
        une vérification officielle.</b>
        </div>
        """,
        unsafe_allow_html=True
    )

    fichier = st.file_uploader(
        "Photo ou scan du document",
        type=["png", "jpg", "jpeg"],
        key="upload_" + dossier["id"]
    )

    if fichier:

        st.success(f"📄 Document reçu : {fichier.name}")

        st.image(
            fichier,
            use_container_width=True
        )

        if st.button(
            "🤖 Analyser le document",
            key="analyse_" + dossier["id"],
            use_container_width=True
        ):

            if not GEMINI_OK:

                st.error("❌ Le module Gemini n'est pas installé.")

                st.code("py -m pip install google-genai")

            elif not gemini_configure():

                st.error(
                    "❌ GEMINI_API_KEY n'est pas configurée dans Streamlit Secrets."
                )

                st.info(
                    "Allez dans Settings → Secrets et ajoutez GEMINI_API_KEY."
                )

            else:

                with st.spinner("🤖 Analyse du document..."):

                    resultat = analyser_document(
                        fichier,
                        dossier["nom"],
                        dossier.get("documents", [])
                    )

                if resultat:

                    st.success("✅ Analyse terminée !")

                    st.markdown("### 🤖 Résultat")

                    st.markdown(resultat)

                    dossier.setdefault("analyses", [])

                    dossier["analyses"].append(
                        {
                            "fichier": fichier.name,
                            "date": maintenant(),
                            "resultat": resultat
                        }
                    )

                    sauvegarder()

    analyses = dossier.get("analyses", [])

    if analyses:

        st.divider()

        st.markdown("### 🕘 Analyses précédentes")

        for analyse in reversed(analyses):

            with st.expander(
                "📄 "
                + analyse.get("fichier", "Document")
                + " — "
                + analyse.get("date", "")
            ):

                st.markdown(
                    analyse.get("resultat", "")
                )


if page == "🏠 Accueil":

    st.markdown(
        f"""
        <div class="welcome">
        <h2>👋 Bonjour {profil["prenom"]} !</h2>
        <p>Préparons votre prochaine démarche simplement.</p>
        </div>
        """,
        unsafe_allow_html=True
    )

    dossiers = st.session_state.dossiers

    total_dossiers = len(dossiers)
    dossiers_termines = 0
    documents_faits = 0
    documents_total = 0

    for dossier in dossiers:

        faits, total, pourcentage = calculer_progression(dossier)

        documents_faits += faits
        documents_total += total

        if total > 0 and pourcentage == 100:
            dossiers_termines += 1

    col1, col2, col3 = st.columns(3)

    with col1:
        st.metric("📋 Dossiers", total_dossiers)

    with col2:
        st.metric("🎉 Terminés", dossiers_termines)

    with col3:
        st.metric(
            "✅ Documents",
            f"{documents_faits}/{documents_total}"
        )

    st.markdown("## ✨ Que voulez-vous faire ?")

    col1, col2 = st.columns(2)

    with col1:

        st.markdown(
            """
            <div class="feature">
            <div class="feature-icon">📋</div>
            <h3>Préparer</h3>
            <p>Créez une checklist adaptée à votre démarche.</p>
            </div>
            """,
            unsafe_allow_html=True
        )

    with col2:

        st.markdown(
            """
            <div class="feature">
            <div class="feature-icon">🤖</div>
            <h3>Vérifier</h3>
            <p>Faites analyser vos documents avec l'assistant IA.</p>
            </div>
            """,
            unsafe_allow_html=True
        )

    col1, col2 = st.columns(2)

    with col1:

        st.markdown(
            """
            <div class="feature">
            <div class="feature-icon">📂</div>
            <h3>Organiser</h3>
            <p>Retrouvez toutes vos démarches dans vos dossiers.</p>
            </div>
            """,
            unsafe_allow_html=True
        )

    with col2:

        st.markdown(
            """
            <div class="feature">
            <div class="feature-icon">🧾</div>
            <h3>Tout préparer</h3>
            <p>Suivez votre progression jusqu'à terminer votre checklist.</p>
            </div>
            """,
            unsafe_allow_html=True
        )

    if dossiers:

        st.markdown("## 📊 Mes derniers dossiers")

        for dossier in dossiers[-3:]:

            faits, total, pourcentage = calculer_progression(dossier)

            st.write(f"**📋 {dossier['nom']}**")

            st.progress(pourcentage / 100)

            st.caption(
                f"{faits}/{total} documents • {pourcentage}%"
            )


elif page == "➕ Nouvelle démarche":

    st.markdown("## ➕ Nouvelle démarche")

    situation = st.selectbox(
        "Quelle démarche souhaitez-vous préparer ?",
        [
            "Carte d'identité",
            "Passeport",
            "Permis de conduire",
            "Changement d'adresse",
            "Inscription scolaire",
            "Création d'entreprise",
            "Autre"
        ]
    )

    if situation != "Autre":

        documents = checklist_demarche(
            situation,
            profil["logement"]
        )

        st.markdown(
            f"""
            <div class="glass">
            <h2>🧾 {situation}</h2>
            <p>Votre checklist contiendra <b>{len(documents)}</b> document(s).</p>
            </div>
            """,
            unsafe_allow_html=True
        )

        with st.expander("👀 Voir les documents"):

            for document in documents:
                st.write("☐ " + document)

        if st.button(
            "🚀 Créer mon dossier",
            use_container_width=True
        ):

            dossier = creer_dossier(
                situation,
                documents
            )

            st.session_state.dossiers.append(dossier)

            st.session_state.dossier_ouvert = dossier["id"]

            sauvegarder()

            st.success("🎉 Dossier créé avec succès !")

            st.session_state.page = "📋 Mes dossiers"

            st.rerun()

    else:

        st.markdown(
            """
            <div class="premium-card">
            <h3>⭐ Démarche personnalisée</h3>
            <p>
            Décrivez votre démarche et l'assistant pourra créer
            une checklist personnalisée.
            </p>
            </div>
            """,
            unsafe_allow_html=True
        )

        question = st.text_area(
            "Quelle démarche voulez-vous faire ?",
            placeholder="Exemple : je veux demander une aide au logement",
            height=130
        )

        if st.button(
            "🤖 Créer ma checklist personnalisée",
            use_container_width=True
        ):

            if not question.strip():

                st.warning("⚠️ Décrivez votre démarche.")

            elif not GEMINI_OK:

                st.error("❌ Gemini n'est pas installé.")

                st.code("py -m pip install google-genai")

            elif not gemini_configure():

                st.error(
                    "❌ GEMINI_API_KEY n'est pas configurée dans Streamlit Secrets."
                )

                st.info(
                    "Allez dans Settings → Secrets et ajoutez GEMINI_API_KEY."
                )

            else:

                client = obtenir_client_gemini()

                prompt = f"""
Tu es l'assistant administratif de
"Checklist à toute épreuve".

L'utilisateur souhaite effectuer cette démarche :

{question}

Crée une checklist prudente des documents
qui peuvent être nécessaires.

Réponds uniquement avec une liste à puces.

Exemple :

- Pièce d'identité
- Justificatif de domicile
- Document complémentaire

Règles :

- Ne donne aucune garantie officielle.
- Ne devine pas.
- Utilise des formulations prudentes.
- Les documents peuvent dépendre de la situation.
"""

                try:

                    with st.spinner(
                        "🤖 Création de votre checklist..."
                    ):

                        response = client.models.generate_content(
                            model="gemini-3.6-flash",
                            contents=prompt
                        )

                    texte = response.text

                    documents = []

                    for ligne in texte.splitlines():

                        ligne = ligne.strip()

                        if ligne.startswith("- "):

                            document = ligne[2:].strip()

                            if document:
                                documents.append(document)

                    if not documents:

                        st.warning(
                            "⚠️ Impossible de créer une checklist."
                        )

                    else:

                        dossier = creer_dossier(
                            question,
                            documents
                        )

                        st.session_state.dossiers.append(dossier)

                        st.session_state.dossier_ouvert = dossier["id"]

                        sauvegarder()

                        st.success(
                            "🎉 Checklist personnalisée créée !"
                        )

                        st.session_state.page = "📋 Mes dossiers"

                        st.rerun()

                except Exception as erreur:

                    st.error("❌ Erreur pendant la création.")

                    st.code(str(erreur))


elif page == "📋 Mes dossiers":

    st.markdown("## 📋 Mes dossiers")

    dossiers = st.session_state.dossiers

    if not dossiers:

        st.markdown(
            """
            <div class="glass">
            <h2>📭 Aucun dossier</h2>
            <p>Créez votre première démarche pour commencer.</p>
            </div>
            """,
            unsafe_allow_html=True
        )

        if st.button(
            "➕ Créer une démarche",
            use_container_width=True
        ):

            st.session_state.page = "➕ Nouvelle démarche"

            st.rerun()

    else:

        recherche = st.text_input(
            "🔎 Rechercher un dossier",
            placeholder="Exemple : passeport"
        )

        if recherche.strip():

            dossiers_affiches = [
                dossier
                for dossier in dossiers
                if recherche.lower()
                in dossier.get("nom", "").lower()
            ]

        else:

            dossiers_affiches = dossiers

        if not dossiers_affiches:
            st.info("🔎 Aucun dossier trouvé.")

        for dossier in dossiers_affiches:

            faits, total, pourcentage = calculer_progression(dossier)

            with st.expander(
                f"📋 {dossier['nom']} — {pourcentage}%",
                expanded=(
                    dossier["id"]
                    == st.session_state.dossier_ouvert
                )
            ):

                afficher_dossier(dossier)

                st.divider()

                if st.button(
                    "🗑️ Supprimer ce dossier",
                    key="supprimer_" + dossier["id"],
                    use_container_width=True
                ):

                    st.session_state.dossiers = [
                        d
                        for d in st.session_state.dossiers
                        if d.get("id") != dossier["id"]
                    ]

                    if st.session_state.dossier_ouvert == dossier["id"]:
                        st.session_state.dossier_ouvert = None

                    sauvegarder()

                    st.success("🗑️ Dossier supprimé.")

                    st.rerun()


elif page == "🤖 Assistant":

    st.markdown("## 🤖 Assistant Checklist à toute épreuve")

    st.markdown(
        """
        <div class="glass">
        <h3>💬 Une question ?</h3>
        <p>
        Posez votre question concernant une démarche administrative.
        </p>
        </div>
        """,
        unsafe_allow_html=True
    )

    question = st.text_area(
        "Votre question",
        placeholder="Exemple : quels documents prévoir pour un passeport ?",
        height=150
    )

    if st.button(
        "🤖 Poser ma question",
        use_container_width=True
    ):

        if not question.strip():

            st.warning("⚠️ Écrivez une question.")

        elif not GEMINI_OK:

            st.error("❌ Gemini n'est pas installé.")

            st.code("py -m pip install google-genai")

        elif not gemini_configure():

            st.error(
                "❌ GEMINI_API_KEY n'est pas configurée dans Streamlit Secrets."
            )

            st.info(
                "Allez dans Settings → Secrets et ajoutez GEMINI_API_KEY."
            )

        else:

            with st.spinner("🤖 Réflexion..."):

                resultat = assistant_gemini(question)

            if resultat:

                st.markdown("### 🤖 Réponse")

                st.markdown(resultat)

    st.divider()

    st.caption(
        "⚠️ Les réponses de l'assistant sont indicatives. "
        "Vérifiez toujours les informations auprès de l'administration concernée."
    )


elif page == "👤 Profil":

    st.markdown("## 👤 Mon profil")

    st.markdown(
        """
        <div class="glass">
        <h3>👤 Vos informations</h3>
        <p>
        Ces informations servent à personnaliser vos démarches.
        </p>
        </div>
        """,
        unsafe_allow_html=True
    )

    prenom = st.text_input(
        "Prénom",
        value=profil.get("prenom", "")
    )

    nom = st.text_input(
        "Nom",
        value=profil.get("nom", "")
    )

    email = st.text_input(
        "Email",
        value=profil.get("email", "")
    )

    age = st.number_input(
        "Âge",
        min_value=1,
        max_value=120,
        value=int(profil.get("age", 18))
    )

    nationalites = [
        "Française",
        "Européenne",
        "Autre"
    ]

    ancienne_nationalite = profil.get(
        "nationalite",
        "Française"
    )

    if ancienne_nationalite not in nationalites:
        ancienne_nationalite = "Française"

    nationalite = st.selectbox(
        "Nationalité",
        nationalites,
        index=nationalites.index(
            ancienne_nationalite
        )
    )

    logements = [
        "Je suis propriétaire",
        "Je suis locataire",
        "Je suis hébergé chez quelqu'un"
    ]

    ancien_logement = profil.get(
        "logement",
        logements[0]
    )

    if ancien_logement not in logements:
        ancien_logement = logements[0]

    logement = st.selectbox(
        "Situation de logement",
        logements,
        index=logements.index(
            ancien_logement
        )
    )

    if st.button(
        "💾 Enregistrer mon profil",
        use_container_width=True
    ):

        st.session_state.profil = {
            "prenom": prenom.strip(),
            "nom": nom.strip(),
            "email": email.strip().lower(),
            "age": int(age),
            "nationalite": nationalite,
            "logement": logement
        }

        sauvegarder()

        st.success("✅ Profil enregistré !")

        st.rerun()

    st.divider()

    st.markdown(
        """
        <div class="premium-card">
        <h3>🚀 Évolution de l'application</h3>
        <p>
        La version actuelle ne contient pas encore de système de paiement.
        </p>
        </div>
        """,
        unsafe_allow_html=True
    )

    st.divider()

    st.markdown("### 🗑️ Zone de suppression")

    confirmation = st.checkbox(
        "Je confirme vouloir supprimer mon profil et tous mes dossiers."
    )

    if confirmation:

        if st.button(
            "🗑️ Supprimer toutes mes données",
            use_container_width=True
        ):

            try:

                if os.path.exists(DATA_FILE):
                    os.remove(DATA_FILE)

            except Exception:
                pass

            st.session_state.clear()

            st.rerun()


st.divider()

st.markdown(
    """
    <div class="footer">
    ✅ <b>Checklist à toute épreuve V25</b><br>
    🆓 Version actuelle sans paiement • 💾 Données locales • 🤖 IA optionnelle
    <br><br>
    Les informations fournies sont indicatives.
    Vérifiez toujours les informations auprès de l'administration concernée.
    </div>
    """,
    unsafe_allow_html=True
)
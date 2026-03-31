use rustler::{Atom, Decoder, Error, NifResult, Term};
use sqlformat::{Dialect, FormatOptions, Indent, QueryParams};

rustler::atoms! {
    none,
    named,
    indexed,
    spaces,
    tabs,
    indent,
    keyword_casing,
    lowercase,
    preserve,
    lines_between_queries,
    ignore_case_convert,
    inline,
    max_inline_block,
    max_inline_arguments,
    max_inline_top_level,
    join_layout,
    nested,
    top_level,
    dialect,
    generic,
    postgresql,
    sqlserver
}

#[derive(rustler::NifTaggedEnum)]
enum ParamsInput {
    None,
    Named(Vec<(String, String)>),
    Indexed(Vec<String>),
}

#[derive(rustler::NifTaggedEnum)]
enum IndentInput {
    Spaces(u8),
    Tabs,
}

#[derive(rustler::NifUnitEnum)]
enum DialectInput {
    Generic,
    Postgresql,
    Sqlserver,
}

#[derive(rustler::NifUnitEnum)]
enum KeywordCasingInput {
    Uppercase,
    Lowercase,
    Preserve,
}

#[derive(rustler::NifUnitEnum)]
enum JoinLayoutInput {
    Nested,
    TopLevel,
}

#[rustler::nif(schedule = "DirtyCpu")]
fn format_nif(query: String, params: ParamsInput, options: Term<'_>) -> NifResult<String> {
    let params = decode_params(params);

    let indent = decode_optional_field::<IndentInput>(options, indent())?
        .map(decode_indent)
        .unwrap_or(Indent::Spaces(2));
    let keyword_casing = decode_optional_field::<KeywordCasingInput>(options, keyword_casing())?
        .map(decode_keyword_casing)
        .flatten();
    let lines_between_queries =
        decode_optional_field::<u8>(options, lines_between_queries())?.unwrap_or(1);
    let inline = decode_optional_field::<bool>(options, inline())?.unwrap_or(false);
    let max_inline_block =
        decode_optional_field::<usize>(options, max_inline_block())?.unwrap_or(50);
    let max_inline_arguments =
        decode_optional_field::<Option<usize>>(options, max_inline_arguments())?.flatten();
    let max_inline_top_level =
        decode_optional_field::<Option<usize>>(options, max_inline_top_level())?.flatten();
    let join_layout_is_top_level = decode_optional_field::<JoinLayoutInput>(options, join_layout())?
        .map(decode_join_layout)
        .unwrap_or(false);
    let dialect = decode_optional_field::<DialectInput>(options, dialect())?
        .map(decode_dialect)
        .unwrap_or(Dialect::Generic);

    let ignore_case_convert_owned =
        decode_optional_field::<Option<Vec<String>>>(options, ignore_case_convert())?.flatten();
    let ignore_case_convert = ignore_case_convert_owned
        .as_ref()
        .map(|keywords| keywords.iter().map(String::as_str).collect());

    let format_options = FormatOptions {
        indent,
        uppercase: keyword_casing,
        lines_between_queries,
        ignore_case_convert,
        inline,
        max_inline_block,
        max_inline_arguments,
        max_inline_top_level,
        joins_as_top_level: join_layout_is_top_level,
        dialect,
    };

    Ok(sqlformat::format(&query, &params, &format_options))
}

fn decode_optional_field<'a, T>(options: Term<'a>, key: Atom) -> NifResult<Option<T>>
where
    T: Decoder<'a>,
{
    match options.map_get(key) {
        Ok(value) => value.decode().map(Some),
        Err(Error::BadArg) => Ok(None),
        Err(err) => Err(err),
    }
}

fn decode_params(params: ParamsInput) -> QueryParams {
    match params {
        ParamsInput::None => QueryParams::None,
        ParamsInput::Named(named) => QueryParams::Named(named),
        ParamsInput::Indexed(indexed) => QueryParams::Indexed(indexed),
    }
}

fn decode_indent(indent: IndentInput) -> Indent {
    match indent {
        IndentInput::Spaces(width) => Indent::Spaces(width),
        IndentInput::Tabs => Indent::Tabs,
    }
}

fn decode_dialect(dialect: DialectInput) -> Dialect {
    match dialect {
        DialectInput::Generic => Dialect::Generic,
        DialectInput::Postgresql => Dialect::PostgreSql,
        DialectInput::Sqlserver => Dialect::SQLServer,
    }
}

fn decode_keyword_casing(keyword_casing: KeywordCasingInput) -> Option<bool> {
    match keyword_casing {
        KeywordCasingInput::Uppercase => Some(true),
        KeywordCasingInput::Lowercase => Some(false),
        KeywordCasingInput::Preserve => None,
    }
}

fn decode_join_layout(join_layout: JoinLayoutInput) -> bool {
    match join_layout {
        JoinLayoutInput::Nested => false,
        JoinLayoutInput::TopLevel => true,
    }
}

rustler::init!("Elixir.SqlformatEx");

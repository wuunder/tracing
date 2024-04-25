defmodule OT.Decorator do
  use Decorator.Define, with_span: 0, with_span: 1

  def with_span(body, context) do
    with_span(Atom.to_string(context.name), body, context)
  end

  def with_span(name, body, _context) do
    quote do
      OT.with_span unquote(name) do
        OT.set_attributes(decorator: "true")
        unquote(body)
      end
    end
  end
end

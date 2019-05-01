defmodule PfdsVisualizationsWeb.TreeView do
  use Phoenix.LiveView

  def render(assigns) do
  ~L"""
  <section class="row data-structure-container">
    <h1 class="data-structure-title"><u>Red Black Trees</u></h1>
    <form phx-submit="add_node">
      <input type="text" name="tree-node-input" placeholder="Add a new node..." />
    </form>
    <svg class="tree-container" style="width: 100vw;" viewBox="0 0 <%= @grid[:dimensions][:width] %> <%= @grid[:dimensions][:height] %>">
      <%= visualize(@rb_tree, 0, RedBlackTree.depth(@rb_tree), {@grid[:starting_coordinates][:x], @grid[:starting_coordinates][:y]}) %>
    </svg>
  </section>
  """
  end

  def mount(session, socket) do
    socket =
    socket
    |> assign(:rb_tree, session.rb_tree)
    |> assign(:grid, make_grid(session.rb_tree))
    {:ok, socket}
  end

  def handle_event("add_node", %{"tree-node-input" => input}, socket) do
    tree = socket.assigns.rb_tree
    value = String.to_integer(input)
    new_tree = RedBlackTree.insert(tree, value)
    grid = make_grid(new_tree)
    {:noreply, assign(socket, :rb_tree, new_tree) |> assign(:grid, grid)}
  end

  use PfdsVisualizationsWeb, :view
  alias :math, as: Math
  @node_diameter 6
  @line_spacing 10

  def make_grid(:empty), do: %{width: 100, height: 100, starting_coordinates: %{x: 50, y: @line_spacing }}
  def make_grid(tree) do
    [:set_depth, :calc_dimensions, :set_coordinates]
    |> Enum.reduce(%{}, fn instruction, acc ->
      case instruction do
        :set_depth -> Map.put(acc, :depth, RedBlackTree.depth(tree))
        :calc_dimensions -> Map.put(acc, :dimensions, %{width: Math.pow(2, acc[:depth]) * @node_diameter, height: acc[:depth] + @line_spacing * @line_spacing})
        :set_coordinates -> Map.put(acc, :starting_coordinates, %{x: acc[:dimensions][:width] / 2, y: @line_spacing})
      end
    end)
  end

  def visualize(rb_tree, level, root_depth, {x, y} \\ {50, 10}) do
    draw(rb_tree, %{x: x, y: y, depth: root_depth, level: level})
  end

  defp draw(:empty, %{x: x, y: y}) do
    ~E"""
    <g>
      <circle class="leaf-node" fill="black" cy="<%= y %>" cx="<%= x %>" r="3" />
      <text text-anchor="middle" fill="white" font-size="0.2em" x="<%= x %>" y="<%= y + 1 %>">E</text>
    </g>
    """
  end

  defp draw(%RedBlackTree{left: left_tree, right: right_tree, element: el, color: color}, %{x: x, y: y, depth: depth, level: level}) do
    spread_factor = calculate_spread_factor(depth, level)
    left = visualize(left_tree, level + 1, depth, { x - spread_factor, y + @line_spacing})
    right = visualize(right_tree, level + 1, depth, { x + spread_factor, y + @line_spacing})
    ~E"""
    <g>
      <circle fill="<%= color %>" cy="<%= y %>" cx="<%= x %>" r="3" />
      <text text-anchor="middle" fill="white" font-size="0.2em" x="<%= x %>" y="<%= y + 1 %>"><%= el %></text>
    </g>
    <line x1="<%= x %>" y1="<%= y + 3 %>" x2="<%= x - spread_factor %>" y2="<%= y + 10 %>" stroke="black"
          stroke-width="0.1"
    />
    <%= left %>
    <line x1="<%= x %>" y1="<%= y + 3 %>" x2="<%= x + spread_factor %>" y2="<%= y + 10 %>" stroke="black"
          stroke-width="0.1"
    />
    <%= right %>
    """
  end

  defp calculate_spread_factor(root_depth, level), do: Math.pow(2, root_depth - 2 - level) * @node_diameter
end

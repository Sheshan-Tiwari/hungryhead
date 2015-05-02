class WillPaginate::Collection
  def as_json options={}
    {
      :total_entries => self.total_entries,
      :current_page => self.current_page,
      :total_pages => self.total_pages,
      :per_page => self.per_page,
      :next_page => self.next_page,
      :items => super
    }
  end
end